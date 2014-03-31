#!/usr/bin/env make

##### Configuration

# the identify of each GMS install is unique
RUBY:=$(shell bash -c '(which ruby) || (echo installing ruby ... && sudo apt-get -y -f install ruby1.9.1 >/dev/null 2>&1)')
GMS_ID:=$(shell cat /etc/genome/sysid 2>/dev/null)
ifeq ('$(GMS_ID)','') 
	GMS_ID:=$(shell ruby -e 'n=Time.now.to_i-1373561229; a=""; while(n > 0) do r = n % 36; a = a +  (r<=9 ? r.to_s : (55+r).chr); n=(n/36).to_i end; print a,sprintf("%02d",(rand()*100).to_i),"\n"')
endif
GMS_USER:=genome
GMS_GROUP:=genome

# this path will be a symlink to the installation repo
GMS_HOME:=/opt/gms/$(GMS_ID)

# the account of the current user (run "make home" as any other user after install)
USER_HOME:=$(shell echo "ls -d ~$(USER)" | sh)

# most configuration is moving into Puppet manifests
MANIFEST:='standalone.pp'

# this identifier is used to pick OS-specific targets
LSB_RELEASE:=$(shell which lsb_release)
ifeq ("$(LSB_RELEASE)","")
  OS_VENDOR:=$(shell uname) 
  OS_RELASE:=
else
  OS_VENDOR:=$(shell lsb_release -i 2>/dev/null | awk '{ print $$3 }')
  OS_RELEASE:=$(shell lsb_release -a 2>/dev/null | grep Release | awk '{ print $$2 }')
endif
OS:=$(shell echo $(OS_VENDOR)$(OS_RELEASE))

# the tool to use for bulk file transfer
FTP:=ftp
ifeq ('$(OS_VENDOR)','Ubuntu')
 # FTP:=$(shell which ncftpget || (sudo apt-get install -q -y ncftp && which ncftpget))
 FTP:=wget -v -c
endif

# this value is empty for tools that automatically download to the PWD (ftp, ncftpget, wget)
# and is set to "." for tools that must be told where to download (scp, rsync)
DOWNLOAD_TARGET=
ifeq ('$(FTP)', 'scp')
	DOWNLOAD_TARGET:=.
endif

# installation data that is too big to fit in the git repository is staged here:
# /gscmnt/sata102/info/ftp-staging/pub/software/gms/setup/archive-files -> https://xfer.genome.wustl.edu/gxfer1/project/gms/setup/archive-files/
DATASERVER=https://xfer.genome.wustl.edu/gxfer1/project/gms/setup/archive-files

# when tarballs of software and data are updated they are given new names
APPS_DUMP_VERSION=2014-01-16
JAVA_DUMP_VERSION=2013-08-27
APT_DUMP_VERSION=2014.03.31

# other config info
IP:=$(shell /sbin/ifconfig | grep 'inet addr' | perl -ne '/inet addr:(\S+)/ && print $$1,"\n"' | grep -v 127.0.0.1)
HOSTNAME:=$(shell hostname)
PWD:=$(shell pwd)

# ensure the local directory is present for steps with results outside of the directory
$(shell [ -e `readlink done-host` ] || mkdir -p `readlink done-host`)

# Control the git commit for each of the underlying repos.
# Git submodules would work for this but they do odd things with storing aboslute paths.
GIT_VERSION_UR:=gms-pub-tag-2
GIT_VERSION_GENOME:=gms-pub
GIT_VERSION_WORKFLOW:=gms-pub
GIT_VERSION_RAILS:=gms-pub
GIT_VERSION_OPENLAVA:=2.2

              
##### Primary Targets

# in a non-VM environment the default target "all" will build the entire system
all: 
	#
	# $@:
	# Install the GMS on the local Ubuntu 12.04 (Precise) host...
	#
	sudo -v
	make home
	DEBIAN_FRONTEND=noninteractive make setup
	#
	# *** LOG OUT and log back in to ensure your environment is properly initialized! ***
	#

# in a VM environment, the staging occurs on the host, and the rest on the VM
vm: vminit
	#
	# $@:
	# log into the vm to finish the make process
	#
	sudo -v
	vagrant ssh -c 'cd /vagrant && make home && DEBIAN_FRONTEND=noninteractive make setup'
	#
	# now run "vagrant ssh" to log into the new GMS
	#

# for debugging variables
vars:
	#
	# $@:
	#
	# GMS_ID: $(GMS_ID)
	# GMS_USER: $(GMS_USER)
	# GMS_HOME: $(GMS_HOME)
	# USER_HOME: $(USER_HOME)
	# UNAME: $(UNAME)
	# OS_VENDOR: $(OS_VENDOR)
	# OS_RELEASE: $(OS_RELEASE)
	# OS: $(OS)
	# FTP: $(FTP)
	# DATASERVER: $(DATASERVER)
	# DOWNLOAD_TARGET: $(DOWNLOAD_TARGET)
	# APPS_DUMP_VERSION: $(APPS_DUMP_VERSION)
	# APT_DUMP_VERSION: $(APT_DUMP_VERSION)
	# DATA_DUMP_VERSION: $(DATA_DUMP_VERSION)
	# IP: $(IP)
	# HOSTNAME: $(HOSTNAME)
	# PWD: $(PWD)

##### Behind done-host/vminit: These steps are only run when setting up a VM host.

VAGRANT_DEB:=vagrant_1.5.1_x86_64.deb
VIRTUALBOX_VERSION:=4.3.8

VIRTUALBOX_UBUNTU_LUCID_DEB=virtualbox-4.3_4.3.8-92456~Ubuntu~lucid_amd64.deb
done-host/vminstall-Ubuntu10.04:
	#
	# $@:
	#
	sudo -v
	cd setup/archive-files; [ -e $(VIRTUALBOX_UBUNTU_LUCID_DEB) ] || wget http://download.virtualbox.org/virtualbox/$(VIRTUALBOX_VERSION))/$(VIRTUALBOX_UBUNTU_LUCID_DEB)
	sudo dpkg -i setup/archive-files/$(VIRTUALBOX_UBUNTU_LUCID_DEB) || (echo "***fixing deps***" && (sudo apt-get -y update; sudo apt-get -y -f install))
	sudo apt-get -y install gcc linux-headers-3.0.0-16-server 
	sudo /etc/init.d/virtualbox start|| sudo /etc/init.d/vboxdrv setup
	cd setup/archive-files; [ -e $(VAGRANT_DEB) ] || wget https://dl.bintray.com/mitchellh/vagrant/$(VAGRANT_DEB)
	sudo dpkg -i setup/archive-files/$(VAGRANT_DEB)
	vagrant plugin install vagrant-vbguest
	touch $@
	
VIRTUALBOX_UBUNTU_PRECISE_DEB=virtualbox-4.3_4.3.8-92456~Ubuntu~precise_amd64.deb
done-host/vminstall-Ubuntu12.04:
	#
	# $@:
	#
	sudo -v
	cd setup/archive-files; [ -e $(VIRTUALBOX_UBUNTU_PRECISE_DEB) ] || wget http://download.virtualbox.org/virtualbox/$(VIRTUALBOX_VERSION)/$(VIRTUALBOX_UBUNTU_PRECISE_DEB)
	sudo dpkg -i setup/archive-files/$(VIRTUALBOX_UBUNTU_PRECISE_DEB) || (echo "***fixing deps***" && (sudo apt-get -y update; sudo apt-get -y -f install))
	sudo apt-get -y install gcc linux-headers-generic || (echo "UPDATE THE MAKEFILE FOR UBUNTU PRECISE HEADERS" && false) 
	sudo /etc/init.d/virtualbox start|| sudo /etc/init.d/vboxdrv setup
	cd setup/archive-files; [ -e $(VAGRANT_DEB) ] || wget https://dl.bintray.com/mitchellh/vagrant/$(VAGRANT_DEB)
	sudo dpkg -i setup/archive-files/$(VAGRANT_DEB)
	vagrant plugin install vagrant-vbguest
	touch $@

VIRTUALBOX_DMG:=VirtualBox-4.3.8-92456-OSX.dmg
VAGRANT_DMG:=vagrant_1.5.1.dmg
done-host/vminstall-Darwin:
	#
	# $@:
	#
	sudo -v
	which VirtualBox || (cd setup/archive-files; curl -L http://download.virtualbox.org/virtualbox/$(VIRTUALBOX_VERSION)/$(VIRTUALBOX_DMG) -o $(VIRTUALBOX_DMG) && open $(VIRTUALBOX_DMG))
	while [[ ! `which VirtualBox` ]]; do echo "waiting for VirtualBox install to complete..."; sleep 3; done
	which vagrant || (cd setup/archive-files; curl -L https://dl.bintray.com/mitchellh/vagrant/$(VAGRANT_DMG) -o $(VAGRANT_DMG) && open $(VAGRANT_DMG))
	while [[ ! `which vagrant` ]]; do echo "waiting for vagrant install to complete..."; sleep 3; done
	vagrant plugin install vagrant-vbguest
	touch $@

done-host/vminstall:  
	#
	# $@: (recurses into vminstall-$(OS)
	#
	sudo -v
	[ -e done-host/vminstall-$(OS) ] || sudo make done-host/vminstall-$(OS)
	(which VirtualBox && which vagrant && touch done-host/vminstall) || echo "**** run one of the following to auto-install for your platform: vminstall-mac, vminstall-10.04, or vminstall-12.04"
	which VirtualBox || (echo "**** you can install VirtualBox manually from https://www.virtualbox.org/wiki/Downloads")
	which vagrant || (echo "**** you can install vagrant manually from http://downloads.vagrantup.com/")

done-host/vmaddbox: done-host/vminstall
	#
	# $@:
	#
	# intializing vagrant (VirtualBox) VM...
	# these steps occur before the repo is visible on the VM
	#
	sudo -v
	sudo chown -R `whoami`: ~/.vagrant.d
	(vagrant box list | grep '^precise64' >/dev/null && echo "found vagrant precise64 box") || (echo "installing vagrant precise64 box" && vagrant box add precise64 http://files.vagrantup.com/precise64.box)
	touch $@

done-host/vmkernel:
	#
	# $@:
	#
	# intializing vagrant (VirtualBox) VM...
	# these steps occur before the repo is visible on the VM
	#
	sudo -v
	( (which apt-get >/dev/null) &&  ( [ -e `dpkg -L nfs-kernel-server | grep changelog` ] || sudo apt-get -y install -q -y nfs-kernel-server gcc ) ) || echo "nothing to do for Mac.."
	touch $@

vmcreate: done-host/vmaddbox done-host/vmkernel
	#
	# $@: (recurses into done-host/apt-get-update on the VM)
	#
	#
	# the first bootup will fail because the NFS client is not installed 
	#
	sudo -v
	[ ! -e .vagrant ] || sudo chown -R `whoami`: .vagrant
	vagrant up || true 
	sudo chown -R `whoami`: .vagrant
	#
	# fix the above issue by adding NSF to the client
	#
	vagrant ssh -c 'sudo apt-get update -y >/dev/null 2>&1 || true; sudo apt-get -y install -q - --force-yes nfs-client make'
	# vagrant ssh -c '[ -e postinstall.sh ] && sudo ./postinstall.sh'
	#
	# now reload the VM
	# there should be no NFS errors
	#
	vagrant reload  

vmup: vmcreate
	sudo -v
	((vagrant status | grep 'not created') && bash -c 'make vmcreate') || true
	(vagrant status | grep 'running') || vagrant up

vminit: vmup
	#
	# $@:
	#
	# Basic configuration, such as the user and group and sysid.
	#
	sudo -v
	vagrant ssh -c 'cd /vagrant &&  make done-host/vminit'
	#
	# Reload so that additional provisioning can occur
	# now that the above is complete.
	#
	vagrant reload

##### Steps run on the VM from the host via "vagrant ssh"

done-host/vminit:
	#
	# $@:
	# These steps occur early on the VM before it is reloaded. 
	#
	sudo -v
	make done-host/user-home-$(USER)
	make done-host/puppet 
	make done-host/sysid
	touch $@

##### Generic make targets used by other steps

# downloading and unzipping are all done with generic targets
# ...except one that requires special rename handling

done-repo/download-%: 
	#
	# $@:
	#
	sudo -v
	cd setup/archive-files; $(FTP) $(DATASERVER)/`basename $@ | sed s/download-//` $(DOWNLOAD_TARGET)
	touch $@

done-host/unzip-sw-%: done-repo/download-% 
	#
	# $@:
	#
	sudo -v
	sudo chmod -R +w $(GMS_HOME)/sw
	sudo tar -zxvf setup/archive-files/`basename $< | sed s/download-//` -C $(GMS_HOME)/sw
	touch $@ 

done-host/unzip-fs-%: done-repo/download-%
	#
	# $@:
	#
	sudo -v
	sudo chmod -R o+w $(GMS_HOME)/fs
	tar -zxvf setup/archive-files/`basename $< | sed s/download-//` -C $(GMS_HOME)/fs 
	touch $@ 

done-host/unzip-sw-apps-$(APPS_DUMP_VERSION).tgz: done-repo/download-apps-$(APPS_DUMP_VERSION).tgz
	#
	# $@:
	# unzip apps which are not packaged as .debs (publicly available from other sources)
	#
	sudo -v
	sudo chmod -R o+w $(GMS_HOME)/sw
	sudo tar -zxvf setup/archive-files/apps-$(APPS_DUMP_VERSION).tgz -C $(GMS_HOME)/sw
	[ -e $(GMS_HOME)/sw/apps ] || mkdir -p $(GMS_HOME)/sw/apps
	cd $(GMS_HOME)/sw/apps && ln -s ../../sw/apps-$(APPS_DUMP_VERSION)/* . || true
	[ -e $(GMS_HOME)/sw/apps ] 
	touch $@ 


##### These steps only run on the actual GMS host 

done-host/user-home-%: 
	#
	# $@: 
	# copying configuration into the current user's home directory
	# re-run "make home" for any new user...
	#
	# [ `basename $(USER_HOME)` = `basename $@ | sed s/user-home-//` ]
	cp $(PWD)/setup/home/.??* ~$(USER)
	touch $@
	
done-host/sysid: 
	#
	# $@:
	#
	# setup /etc/genome/sysid if it is not present
	# if it is present, verify that it agress with the make variable
	#
	sudo -v
	[ -e /etc/genome/ ] || sudo mkdir /etc/genome
	sudo chmod go-w /etc/genome
	[ -z /etc/genome/sysid ] || sudo bash -c 'echo '$(GMS_ID)' > /etc/genome/sysid'
	# expected sysid is $(GMS_ID)
	cat /etc/genome/sysid
	test "`cat /etc/genome/sysid`" = '$(GMS_ID)' 
	touch $@

done-host/hosts:
	#
	# $@:
	#
	sudo -v
	echo "$(IP) GMS_HOST" | setup/bin/findreplace-gms | sudo bash -c 'cat - >>/etc/hosts'
	touch $@ 

done-host/puppet: done-host/sysid done-host/hosts
	#
	# $@:
	# the bridge over to puppet-based install
	#
	sudo -v
	# these are needed BEFORE we get everything in place to do the full apt-get update
	sudo apt-get update 1>/dev/null 2>&1 || true
	(facter -v | grep 1.7) || (sudo apt-get -y install rubygems && sudo gem install facter && sudo apt-get -y install facter)
	which puppet || sudo apt-get -q -y install puppet # if puppet is already installed do NOT use apt, as the local version might be independent
	bash -l -c 'sudo `which puppet` apply setup/manifests/$(MANIFEST)'
	# add the current user to the correct groups
	sudo usermod -aG $(GMS_GROUP),sudo,fuse $(USER)
	touch $@

done-host/gms-home-raw:
	#
	# $@
	# When not using a VM, create a real /opt/gms
	#	
	[ -d "/opt/gms" ] || sudo mkdir -p "/opt/gms"
	sudo chown $(GMS_USER):$(GMS_GROUP) /opt/gms /opt/gms/.*
	sudo chmod g+rwxs /opt/gms /opt/gms/.*
	touch $@

done-host/gms-home: done-host/puppet
	#
	# $@: (recurses into done-host/gms-home-{raw,vm})
	#
	sudo -v
	# the creation of /opt/gms varies depending on whether this is a VM or not
	[ -e /vagrant ] || make done-host/gms-home-raw
	# set permissions on the root directory above the GMS home so that additional systems can attach
	sudo touch /opt/gms/test
	sudo chown $(GMS_USER):$(GMS_GROUP) /opt/gms /opt/gms/.* /opt/gms/*
	sudo chmod g+rwxs /opt/gms /opt/gms/.* /opt/gms/*
	# make the home for this GMS
	[ -d "$(GMS_HOME)" ] || sudo mkdir -p $(GMS_HOME)
	# set permissions for $GMS_HOME
	echo GMS_HOME is $(GMS_HOME)
	sudo chown $(GMS_USER):$(GMS_GROUP) $(GMS_HOME)
	sudo chmod g+rwxs $(GMS_HOME)
	# install a directory skeleton
	sudo cp -a setup/gms-home-skel/* $(GMS_HOME)
	sudo mv /opt/gms/$(GMS_ID)/known-systems/LocalSystem.tsv /opt/gms/$(GMS_ID)/known-systems/$(GMS_ID).tsv
	sudo setup/bin/findreplace GMS_HOME $(GMS_HOME) /opt/gms/$(GMS_ID)/known-systems/$(GMS_ID).tsv
	sudo setup/bin/findreplace GMS_ID $(GMS_ID) /opt/gms/$(GMS_ID)/known-systems/$(GMS_ID).tsv
	sudo setup/bin/findreplace HOST_NAME $(HOSTNAME) /opt/gms/$(GMS_ID)/known-systems/$(GMS_ID).tsv
	sudo chown -R $(GMS_USER):$(GMS_GROUP) $(GMS_HOME)
	sudo chmod -R g+ws $(GMS_HOME)
	# since the git repo doesn't keep empty dirs (without .gitkeep), make required subdirs dynamically
	cat setup/dirs | sudo xargs -n 1 -I DIR bash -c 'cd $(GMS_HOME); mkdir -p DIR; sudo chown genome:genome DIR; sudo chmod g+sw DIR'
	sudo rm -f /opt/gms/test
	touch $@

s3fs:
	#
	# $@:
	#
	[ `which s3fs ` ] || make done-host/s3fs-install

done-host/s3fs-install:
	#
	# $@:
	#
	sudo apt-get -y install fuse-utils libfuse-dev libcurl4-openssl-dev libxml2-dev mime-support build-essential
	wget https://s3fs.googlecode.com/files/s3fs-1.73.tar.gz
	tar -zxvf s3fs-1.73.tar.gz
	setup/bin/findreplace 68719476735LL 687194767350LL s3fs-1.73/src/fdcache.cpp
	cp s3fs-1.73/src/s3fs.cpp s3fs-1.73/src/s3fs.cpp.old
	patch -p 0 s3fs-1.73/src/s3fs.cpp < setup/s3fs.cpp.patch
	cd s3fs-* && ./configure && make && sudo make install
	touch $@

setup: s3fs done-host/gms-home done-host/user-home-$(USER) stage-software
	#
	# $@: (recurses into all subsequent steps) after sourcing the /etc/genome.conf file
	#
	# nesting make ensures that the users and environment are set up before running things that depend on them
	sudo bash -l -c 'source /etc/genome.conf; make done-host/rails done-host/apache done-host/db-schema done-host/openlava-install done-host/exim-config'
	touch $@

done-host/etc: done-host/puppet done-host/unzip-sw-apt-mirror-min-ubuntu-12.04-$(APT_DUMP_VERSION).tgz 
	#
	# $@:
	# copy all data from setup/etc into /etc and configure apt sources
	# 
	sudo -v
	[ -d /etc/facter/facts.d ] || sudo mkdir -p /etc/facter/facts.d 
	# Copy apt sources files from setup/etc in /etc/
	/bin/ls setup/etc/ | perl -ne 'chomp; $$o = $$_; s|\+|/|g; $$c = "sudo cp setup/etc/$$o /etc/$$_\n"; print STDERR $$c; print STDOUT $$c' | sudo bash
	# perform various system specific findreplace commands on genome.conf and genome.list
	sudo setup/bin/findreplace REPLACE_GENOME_HOME $(GMS_HOME) /etc/genome.conf /etc/apt/sources.list.d/genome.list
	sudo setup/bin/findreplace REPLACE_GENOME_SYS_ID $(GMS_ID) /etc/genome.conf /etc/apt/sources.list.d/genome.list
	sudo setup/bin/findreplace REPLACE_GENOME_HOST $(HOSTNAME) /etc/genome.conf
	sudo setup/bin/findreplace REPLACE_APT_DUMP_VERSION $(APT_DUMP_VERSION) /etc/apt/sources.list.d/genome.list
	# Add r-cran source and GPG keys for r-cran and TGI
	sudo gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E084DAB9
	sudo gpg -a --export E084DAB9 | sudo apt-key add -
	[ -e genome-institute.asc ] || wget http://apt.genome.wustl.edu/ubuntu/files/genome-institute.asc
	sudo apt-key add genome-institute.asc
	rm genome-institute.asc
	# Remove multi-architecture package support (e.g i386)
	[ ! -e /etc/dpkg/dpkg.cfg.d/multiarch ] || sudo mv /etc/dpkg/dpkg.cfg.d/multiarch /etc/dpkg/dpkg.cfg.d/multiarch.backup
	sudo apt-get -y -f install
	# Set some file permissions
	sudo bash -c 'echo "/opt/gms/$(GMS_ID) *(ro,anonuid=2001,anongid=2001)" >> /etc/exports'	
	sudo chmod +x /etc/facter/facts.d/genome.sh
	touch $@

done-host/apt-get-update: done-host/etc 
	#
	# $@
	#
	sudo -v
	sudo apt-get -y update >/dev/null 2>&1 || true
	touch $@

done-host/pkgs: done-host/apt-get-update
	#
	# $@:
	#
	sudo -v
	# install primary dependency packages 
	sudo apt-get install -q -y --force-yes git-core vim byobu nfs-common perl-doc genome-snapshot-deps `cat setup/packages.lst`
	# install rails dependency packages
	sudo apt-get install -q -y --force-yes git ruby1.9.1 ruby1.9.1-dev rubygems1.9.1 irb1.9.1 ri1.9.1 rdoc1.9.1 build-essential apache2 libopenssl-ruby1.9.1 libssl-dev zlib1g-dev libcurl4-openssl-dev apache2-prefork-dev libapr1-dev libaprutil1-dev postgresql postgresql-contrib libpq-dev libxslt-dev libxml2-dev genome-rails-prod
	# install unpackaged Perl modules
	# download cpanm unless it is already in the gms repo
	#[ -e setup/bin/cpanm ] || (curl -L https://raw.github.com/miyagawa/cpanminus/master/cpanm >| setup/bin/cpanm && chmod +x setup/bin/cpanm)
	# install DBD:Pg && Module::Runtime directly from CPAN. These should be replaced with debian packages eventually
	#sudo setup/bin/cpanm DBD::Pg@2.19.3
	touch $@

done-host/git-checkouts:
	#
	# $@:
	# This is a little complicated b/c old versions of git don't emit a bad exit code
	# when a required branch does not exist.
	#
	sudo -v
	which git || (which apt-get && sudo apt-get install git) || (echo "*** please install git on your system to continue ***" && false)
	[ -e $(GMS_HOME)/sw/ur/.git ] 		|| (sudo git clone http://github.com/genome/UR.git $(GMS_HOME)/sw/ur && cd $(GMS_HOME)/sw/ur && sudo git checkout $(GIT_VERSION_UR)) 
	cd $(GMS_HOME)/sw/ur/ && git ls-remote --exit-code . $(GIT_VERSION_UR) 1>/dev/null || (echo "failed to clone ur repo" && false)
	[ -e $(GMS_HOME)/sw/workflow/.git ] || sudo git clone http://github.com/genome/tgi-workflow.git $(GMS_HOME)/sw/workflow && cd $(GMS_HOME)/sw/workflow && sudo git checkout $(GIT_VERSION_WORKFLOW) 
	cd $(GMS_HOME)/sw/workflow/ && git ls-remote --exit-code . $(GIT_VERSION_WORKFLOW) 1>/dev/null || (echo "failed to clone workflow repo" && false)
	[ -e $(GMS_HOME)/sw/rails/.git ] 	|| sudo git clone http://github.com/genome/gms-webviews.git $(GMS_HOME)/sw/rails && cd $(GMS_HOME)/sw/rails && sudo git checkout $(GIT_VERSION_RAILS) 
	cd $(GMS_HOME)/sw/rails/ && git ls-remote --exit-code . $(GIT_VERSION_RAILS) 1>/dev/null || (echo "failed to clone gms-webviews repo" && false)	
	[ -e $(GMS_HOME)/sw/genome/.git ] 	|| sudo git clone http://github.com/genome/gms-core.git $(GMS_HOME)/sw/genome && cd $(GMS_HOME)/sw/genome && sudo git checkout $(GIT_VERSION_GENOME)	
	cd $(GMS_HOME)/sw/genome/ && git ls-remote --exit-code . $(GIT_VERSION_GENOME) 1>/dev/null || (echo "failed to clone gms-core repo" && false)	
	[ -e $(GMS_HOME)/sw/openlava/.git ] || sudo git clone http://github.com/openlava/openlava.git $(GMS_HOME)/sw/openlava && cd $(GMS_HOME)/sw/openlava && sudo git checkout $(GIT_VERSION_OPENLAVA)
	cd $(GMS_HOME)/sw/openlava/ && git ls-remote --exit-code . $(GIT_VERSION_OPENLAVA) 1>/dev/null || (echo "failed to clone openlava repo" && false)	
	sudo chown -R $(GMS_USER):$(GMS_GROUP) $(GMS_HOME)/sw
	sudo chmod -R g+rwxs $(GMS_HOME)/sw
	touch $@

done-host/openlava-compile: done-host/git-checkouts done-host/hosts done-host/etc done-host/pkgs
	#
	# $@:
	#
	sudo -v
	cd $(GMS_HOME)/sw/openlava && ./bootstrap.sh && make && make check && sudo make install 
	touch $@

done-host/openlava-install: done-host/openlava-compile
	#
	# $@:
	#
	sudo -v
	sudo chown -R genome:root /opt/openlava-2.2/work/
	sudo chmod +x /etc/init.d/openlava
	sudo update-rc.d openlava defaults 98 02 || echo ...
	sudo cp setup/openlava-config/lsb.queues /opt/openlava-2.2/etc/lsb.queues
	cat setup/openlava-config/lsf.cluster.openlava | setup/bin/findreplace-gms >| /tmp/lsf.cluster.openlava
	sudo cp /tmp/lsf.cluster.openlava /opt/openlava-2.2/etc/lsf.cluster.openlava
	sudo rm /tmp/lsf.cluster.openlava
	cd $(GMS_HOME)/sw/openlava/config; sudo cp lsb.hosts lsb.params lsb.users lsf.conf lsf.shared lsf.task openlava.sh openlava.csh /opt/openlava-2.2/etc/
	cd /etc; [ -e lsf.conf ] || sudo ln -s ../opt/openlava-2.2/etc/lsf.conf lsf.conf
	(grep 127.0.1.1 /etc/hosts >/dev/null && sudo bash -c 'grep 127.0 /etc/hosts >> /opt/openlava-2.2/etc/hosts && setup/bin/findreplace localhost `hostname` /opt/openlava-2.2/etc/hosts') || true
	sudo /etc/init.d/openlava start || sudo /etc/init.d/openlava restart
	sudo /etc/init.d/openlava status
	touch $@

done-host/db-init: done-host/pkgs 
	#
	# $@:
	# 
	# setup the database and user "genome"
	sudo -v
	sudo -u postgres /usr/bin/createuser -A -D -R -E genome || echo 
	sudo -u postgres /usr/bin/createdb -T template0 -O genome genome || echo 
	sudo -u postgres /usr/bin/psql postgres -tAc "ALTER USER \"genome\" WITH PASSWORD 'changeme'"
	sudo -u postgres /usr/bin/psql -c "GRANT ALL PRIVILEGES ON database genome TO \"genome\";"
	# configure how posgres takes connections
	echo 'local   all         postgres                          ident' >| /tmp/pg_hba.conf
	echo 'local   all         all                               password' >> /tmp/pg_hba.conf
	echo 'host    all         all         127.0.0.1/32          password' >> /tmp/pg_hba.conf
	sudo mv /tmp/pg_hba.conf /etc/postgresql/9.1/main/pg_hba.conf
	sudo chown postgres  /etc/postgresql/9.1/main/pg_hba.conf
	# restart postgres
	sudo /etc/init.d/postgresql restart
	touch $@

done-host/rails: done-host/pkgs
	#
	# $@:
	# 
	sudo -v
	sudo gem install bundler --no-ri --no-rdoc --install-dir=/var/lib/gems/1.9.1
	sudo chown www-data:www-data /var/www
	sudo -u www-data rsync -r $(GMS_HOME)/sw/rails/ /var/www/gms-webviews
	# cd /var/www/gms-webviews && sudo bundle install
	sudo /usr/bin/gem1.9.1 install bundler --no-ri --no-rdoc
	sudo -u www-data  mv /var/www/gms-webviews/config/database.yml.template /var/www/gms-webviews/config/database.yml
	cd /var/www/gms-webviews && sudo bundle install && cd -
	cd /var/www/gms-webviews &&  sudo -u www-data bundle exec bundle exec rake assets:precompile && cd -
	[ -e /var/www/gms-webviews/tmp ] || sudo -u www-data mkdir /var/www/gms-webviews/tmp
	sudo -u www-data touch /var/www/gms-webviews/tmp/restart.txt
	touch $@

done-host/apache: done-host/pkgs 
	#
	# $@:
	# 
	sudo -v
	echo '<VirtualHost *:80>' >| /tmp/gms-webviews.conf
	echo '  ServerName localhost' >> /tmp/gms-webviews.conf
	echo '  ServerAlias some_hostname some_other_hostname' >> /tmp/gms-webviews.conf
	echo '  DocumentRoot /opt/gms' >> /tmp/gms-webviews.conf
	echo '  Alias /data /opt/gms' >> /tmp/gms-webviews.conf
	echo '  Alias /opt/gms /opt/gms' >> /tmp/gms-webviews.conf
	echo '  <Directory /opt/gms>' >> /tmp/gms-webviews.conf
	echo '    Order deny,allow' >> /tmp/gms-webviews.conf
	echo '    Allow from all' >> /tmp/gms-webviews.conf
	echo '    Options +Indexes +FollowSymLinks +MultiViews' >> /tmp/gms-webviews.conf
	echo '  </Directory>' >> /tmp/gms-webviews.conf
	echo '  <Location /data>' >> /tmp/gms-webviews.conf
	echo '    PassengerEnabled off' >> /tmp/gms-webviews.conf
	echo '  </Location>' >> /tmp/gms-webviews.conf
	echo '  <Location /opt/gms>' >> /tmp/gms-webviews.conf
	echo '    PassengerEnabled off' >> /tmp/gms-webviews.conf
	echo '  </Location>' >> /tmp/gms-webviews.conf
	echo '  Alias / /var/www/gms-webviews/public' >> /tmp/gms-webviews.conf
	echo '  <Location />' >> /tmp/gms-webviews.conf
	echo '    PassengerBaseURI /' >> /tmp/gms-webviews.conf
	echo '    PassengerAppRoot /var/www/gms-webviews' >> /tmp/gms-webviews.conf
	echo '  </Location>' >> /tmp/gms-webviews.conf
	echo '  <Directory /var/www/gms-webviews/public>' >> /tmp/gms-webviews.conf
	echo '    Allow from all' >> /tmp/gms-webviews.conf
	echo '    Options -MultiViews' >> /tmp/gms-webviews.conf
	echo '  </Directory>' >> /tmp/gms-webviews.conf
	echo '  AddOutputFilterByType DEFLATE text/html text/css text/plain text/xml application/json' >> /tmp/gms-webviews.conf
	echo '  AddOutputFilterByType DEFLATE image/jpeg, image/png, image/gif' >> /tmp/gms-webviews.conf
	echo '</VirtualHost>' >> /tmp/gms-webviews.conf 
	#
	sudo mv /tmp/gms-webviews.conf /etc/apache2/sites-available/gms-webviews.conf
	( [ -e /etc/apache2/sites-enabled/000-default ] && sudo rm /etc/apache2/sites-enabled/000-default ) || true 
	[ -e /etc/apache2/sites-enabled/gms-webviews.conf ] || sudo ln -s  /etc/apache2/sites-available/gms-webviews.conf  /etc/apache2/sites-enabled/gms-webviews.conf
	sudo service apache2 restart
	sudo update-rc.d apache2 enable 345
	touch $@

done-host/db-schema: done-host/db-init done-host/hosts
	#
	# $@:
	# 
	sudo -v
	sudo -u postgres psql -d genome -f setup/schema.psql	
	sudo bash -l -c 'source /etc/genome.conf; /usr/bin/perl setup/prime-disk-allocations.pl'
	sudo bash -l -c 'source /etc/genome.conf; /usr/bin/perl setup/prime-timeline-allocations.pl'
	sudo bash -l -c 'source /etc/genome.conf; /usr/bin/perl setup/prime-sqlite.pl'
	sudo bash -l -c 'source /etc/genome.conf; ($(GMS_HOME)/sw/genome/bin/genome-perl $(GMS_HOME)/sw/genome/bin/genome disk volume list | grep reads >/dev/null)' 
	touch $@ 

done-host/custom-r: done-host/pkgs
	#
	# $@
	#
	# Install a local custom version of R with all desired packages from CRAN, Bioconductor, and ad hoc sources
	sudo -v
	sudo bash -l -c 'source /etc/genome.conf; /bin/bash setup/install_custom_r/install_custom_r.sh'
	grep -P "1.*R PACKAGE INSTALL SUCCESS" $(GMS_HOME)/sw/apps/R/R-2.15.2/test_r_packages.stdout || (echo "R package install failed" && false)
	touch $@

done-host/exim-config: done-host/pkgs
	#
	# $@
	#
	# Configure Exim to send LSF job reports when jobs complete.
	sudo cp setup/etc/update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf
	sudo setup/bin/findreplace HOST_NAME $(HOSTNAME) /etc/exim4/update-exim4.conf.conf
	sudo update-exim4.conf
	touch $@

stage-software: done-host/pkgs done-host/git-checkouts done-host/unzip-sw-apps-$(APPS_DUMP_VERSION).tgz done-host/unzip-sw-java-$(JAVA_DUMP_VERSION).tgz 


##### Optional maintenance targets:

home: done-host/user-home-$(USER)
	#
	# $@:
	#
	# add the current user to the correct groups
	sudo usermod -aG $(GMS_GROUP),sudo,fuse $(USER) || true # wait for groups to be defined
	
update-repos:
	#
	# $@:
	#
	sudo -v
	cd $(GMS_HOME)/sw/genome; git pull origin $(GIT_VERSION_GENOME) 
	cd $(GMS_HOME)/sw/ur; git pull origin $(GIT_VERSION_UR)
	cd $(GMS_HOME)/sw/workflow; git pull origin $(GIT_VERSION_WORKFLOW)
	cd $(GMS_HOME)/sw/rails; git pull origin $(GIT_VERSION_RAILS) 
	[ -d /var/www/gms-webviews ] || sudo mkdir /var/www/gms-webviews
	sudo chown -R www-data:www-data /var/www/gms-webviews/
	sudo -u www-data rsync -r $(GMS_HOME)/sw/rails/ /var/www/gms-webviews
	sudo service apache2 restart

db-drop:
	#
	# $@:
	#
	sudo -v
	sudo -u postgres /usr/bin/dropdb genome
	[ -e drop/db-schema ] && rm drop/db-schema || echo
	[ -e drop/db-data ] && rm drop/db-data || echo

db-rebuild:
	#
	# $@:
	#
	sudo -v
	sudo -u postgres /usr/bin/dropdb genome || echo
	[ -e drop/db-schema ] && rm drop/db-schema || echo
	[ -e drop/db-data ] && rm drop/db-data || echo
	sudo -u postgres /usr/bin/createdb -T template0 -O genome genome
	sudo -u postgres /usr/bin/psql -c "GRANT ALL PRIVILEGES ON database genome TO \"genome\";"
	sudo -u postgres psql -d genome -f setup/schema.psql	
	setup/prime-disk-allocations.pl
	setup/prime-timeline-allocations.pl
	sudo touch done-host/db-schema

