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
 #FTP:=$(shell which ncftpget || (sudo apt-get install -q -y ncftp && which ncftpget))
 FTP:=wget -v -c
endif

# this value is empty for tools that automatically download to the PWD (ftp, ncftpget, wget)
# and is set to "." for tools that must be told where to download (scp, rsync)
DOWNLOAD_TARGET=
ifeq ('$(FTP)', 'scp')
	DOWNLOAD_TARGET:=.
endif

# data which is too big to fit in the git repository is staged here
DATASERVER=http://genome.wustl.edu/pub/software/gms/testdata/GMS1/setup/archive-files

# staging locations: (when using these, switch the $FTP tool above as necessary
# scp: DATASERVER=blade12-1-1:/gscmnt/sata102/info/ftp-staging/pub/software/gms/testdata/GMS1/setup/archive-files -> http://genome.wustl.edu/pub/software/gms/GMS1/setup/archive-files
# scp: DATASERVER=clinus234:/opt/gms/GMS1/setup/archive-files
# ftp: DATASERVER=ftp://clinus234/setup/archive-files

# when tarballs of software and data are updated they are given new names
APPS_DUMP_VERSION=2013-10-01
JAVA_DUMP_VERSION=2013-08-27
APT_DUMP_VERSION=2013.10.19

# other config info
IP:=$(shell /sbin/ifconfig | grep 'inet addr' | perl -ne '/inet addr:(\S+)/ && print $$1,"\n"' | grep -v 127.0.0.1)
HOSTNAME:=$(shell hostname)
PWD:=$(shell pwd)

# ensure the local directory is present for steps with results outside of the directory
$(shell [ -e `readlink done-host` ] || mkdir -p `readlink done-host`)

              
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
	# LOG OUT and log back in to ensure your environment is properly initialized
	#

# in a VM environment, the staging occurs on the host, and the rest on the VM
vm: vminit
	#
	# $@:
	# log into the vm to finish the make process
	#
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

done-host/vminstall-Ubuntu10.04:
	#
	# $@:
	#
	sudo -v
	cd setup/archive-files; wget http://download.virtualbox.org/virtualbox/4.2.10/virtualbox-4.2_4.2.10-84104~Ubuntu~lucid_amd64.deb 
	sudo dpkg -i setup/archive-files/virtualbox-4.2_4.2.10-84104~Ubuntu~lucid_amd64.deb || (echo "***fixing deps***" && (sudo apt-get -y update; sudo apt-get -y -f install))
	sudo apt-get -y install gcc linux-headers-3.0.0-16-server 
	sudo /etc/init.d/vboxdrv setup
	cd setup/archive-files; wget http://files.vagrantup.com/packages/87613ec9392d4660ffcb1d5755307136c06af08c/vagrant_x86_64.deb
	sudo dpkg -i setup/archive-files/vagrant_x86_64.deb
	touch $@
	
done-host/vminstall-Ubuntu12.04:
	#
	# $@:
	#
	sudo -v
	cd setup/archive-files; [ -e virtualbox-4.2_4.2.10-84104~Ubuntu~precise_amd64.deb ] || wget http://download.virtualbox.org/virtualbox/4.2.10/virtualbox-4.2_4.2.10-84104~Ubuntu~precise_amd64.deb 
	sudo dpkg -i setup/archive-files/virtualbox-4.2_4.2.10-84104~Ubuntu~precise_amd64.deb || (echo "***fixing deps***" && (sudo apt-get -y update; sudo apt-get -y -f install))
	sudo apt-get -y install gcc linux-headers-generic || (echo "UPDATE THE MAKEFILE FOR UBUNTU PRECISE HEADERS" && false) 
	sudo /etc/init.d/vboxdrv setup
	cd setup/archive-files; [ -e vagrant_x86_64.deb ] || wget http://files.vagrantup.com/packages/87613ec9392d4660ffcb1d5755307136c06af08c/vagrant_x86_64.deb
	sudo dpkg -i setup/archive-files/vagrant_x86_64.deb
	touch $@

done-host/vminstall-Darwin:
	#
	# $@:
	#
	sudo -v
	which VirtualBox || (cd setup/archive-files; curl -L http://download.virtualbox.org/virtualbox/4.2.16/VirtualBox-4.2.16-86992-OSX.dmg -o virtualbox.dmg && open virtualbox.dmg)
	while [[ ! `which VirtualBox` ]]; do echo "waiting for VirtualBox install to complete..."; sleep 3; done
	which vagrant || (cd setup/archive-files; curl -L http://files.vagrantup.com/packages/7ec0ee1d00a916f80b109a298bab08e391945243/Vagrant-1.2.7.dmg -o Vagrant.dmg && open Vagrant.dmg)
	while [[ ! `which vagrant` ]]; do echo "waiting for vagrant install to complete..."; sleep 3; done
	touch $@

done-host/vminstall:  
	#
	# $@: (recurses into vminstall-$(OS)
	#
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
	(vagrant box list | grep '^precise64' >/dev/null && echo "found vagrant precise64 box") || (echo "installing vagrant precise64 box" && vagrant box add precise64 http://files.vagrantup.com/precise64.box)
	touch $@

done-host/vmkernel:
	#
	# $@:
	#
	# intializing vagrant (VirtualBox) VM...
	# these steps occur before the repo is visible on the VM
	#
	( (which apt-get >/dev/null) &&  ( [ -e `dpkg -L nfs-kernel-server | grep changelog` ] || sudo apt-get -y install -q -y nfs-kernel-server gcc ) ) || echo "nothing to do for Mac.."
	touch $@

vmcreate: done-host/vmaddbox done-host/vmkernel
	#
	# $@: (recurses into done-host/apt-get-update on the VM)
	#
	#
	# the first bootup will fail because the NFS client is not installed 
	#
	vagrant up || true 
	#
	# fix the above issue by adding NSF to the client
	#
	vagrant ssh -c 'sudo apt-get update -y >/dev/null 2>&1 || true; sudo apt-get -y install -q - --force-yes nfs-client make'
	#vagrant ssh -c '[ -e postinstall.sh ] && sudo ./postinstall.sh'
	#
	# now reload the VM
	# there should be no NFS errors
	#
	vagrant reload  

vmup: vmcreate
	((vagrant status | grep 'not created') && bash -c 'make vmcreate') || true
	(vagrant status | grep 'running') || vagrant up

vminit: vmup
	#
	# $@:
	#
	vagrant ssh -c 'cd /vagrant &&  make done-host/vminit'

##### Steps run on the VM from the host via "vagrant ssh"

done-host/vminit:
	#
	# $@:
	# these steps can be done in parallel with stage-software
	#
	sudo -v
	# Since /tmp has been mounted to a new disk make sure the permissions are set correctly immediately
	sudo chmod -R 1777 /tmp
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

done-repo/unzip-sw-%: done-repo/download-% 
	#
	# $@:
	#
	sudo -v
	sudo chmod -R +w $(GMS_HOME)/sw
	tar -zxvf setup/archive-files/`basename $< | sed s/download-//` -C $(GMS_HOME)/sw
	touch $@ 

done-repo/unzip-fs-%: done-repo/download-%
	#
	# $@:
	#
	sudo -v
	sudo chmod -R o+w $(GMS_HOME)/fs
	tar -zxvf setup/archive-files/`basename $< | sed s/download-//` -C $(GMS_HOME)/fs 
	touch $@ 

done-repo/unzip-sw-apps-$(APPS_DUMP_VERSION).tgz: done-repo/download-apps-$(APPS_DUMP_VERSION).tgz
	#
	# $@:
	# unzip apps which are not packaged as .debs (publicly available from other sources)
	#
	sudo -v
	sudo chmod -R o+w $(GMS_HOME)/sw
	tar -zxvf setup/archive-files/apps-$(APPS_DUMP_VERSION).tgz -C $(GMS_HOME)/sw
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
	#[ `basename $(USER_HOME)` = `basename $@ | sed s/user-home-//` ]
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
	sudo bash -l -c 'source /etc/genome.conf; make done-host/rails done-host/apache done-host/db-schema done-host/openlava-install'
	touch $@

done-host/apt-config: done-host/puppet done-repo/unzip-sw-apt-mirror-min-ubuntu-12.04-$(APT_DUMP_VERSION).tgz
	#
	# $@:
	# done-host/apt-config:
	# configure apt to use the GMS repository
	#
	sudo -v
	sudo dpkg --force-confdef --force-confnew -i $(GMS_HOME)/sw/apt-mirror-min-ubuntu-12.04-$(APT_DUMP_VERSION)/mirror/repo.gsc.wustl.edu/ubuntu/pool/main/g/genome-apt-config/genome-apt-config_1.0.0-2~Ubuntu~precise_all.deb
	/bin/cp setup/debconf.in /tmp
	# findreplace WHATEVER /tmp/debconf.in
	sudo debconf-set-selections < /tmp/debconf.in
	touch $@	

done-host/etc: done-host/apt-config 
	#
	# $@:
	# copy all data from setup/etc into /etc
	# 
	sudo -v
	[ -d /etc/facter/facts.d ] || sudo mkdir -p /etc/facter/facts.d 
	/bin/ls setup/etc/ | perl -ne 'chomp; $$o = $$_; s|\+|/|g; $$c = "cp setup/etc/$$o /etc/$$_\n"; print STDERR $$c; print STDOUT $$c' | sudo bash
	sudo setup/bin/findreplace REPLACE_GENOME_HOME $(GMS_HOME) /etc/genome.conf /etc/apt/sources.list.d/genome.list
	sudo setup/bin/findreplace REPLACE_GENOME_SYS_ID $(GMS_ID) /etc/genome.conf /etc/apt/sources.list.d/genome.list
	sudo setup/bin/findreplace REPLACE_APT_DUMP_VERSION $(APT_DUMP_VERSION) /etc/apt/sources.list.d/genome.list
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
	sudo apt-get install -q -y --force-yes git-core vim nfs-common perl-doc genome-snapshot-deps `cat setup/packages.lst`
	# install rails dependency packages
	sudo apt-get install -q -y --force-yes git ruby1.9.1 ruby1.9.1-dev rubygems1.9.1 irb1.9.1 ri1.9.1 rdoc1.9.1 build-essential apache2 libopenssl-ruby1.9.1 libssl-dev zlib1g-dev libcurl4-openssl-dev apache2-prefork-dev libapr1-dev libaprutil1-dev postgresql postgresql-contrib libpq-dev libxslt-dev libxml2-dev genome-rails-prod
	# install unpackaged Perl modules
	[ -e setup/bin/cpanm ] || (curl -L https://raw.github.com/miyagawa/cpanminus/master/cpanm >| setup/bin/cpanm && chmod +x setup/bin/cpanm)
	sudo setup/bin/cpanm Getopt::Complete
	sudo setup/bin/cpanm DBD::Pg # 2.19.3
	sudo setup/bin/cpanm Set::IntervalTree
	touch $@

done-host/git-checkouts:
	#
	# $@:
	#
	sudo -v
	which git || (which apt-get && sudo apt-get install git) || (echo "*** please install git on your system to continue ***" && false)
	[ -e $(GMS_HOME)/sw/ur/.git ] 			|| git clone http://github.com/genome/UR.git -b gms-pub $(GMS_HOME)/sw/ur
	[ -e $(GMS_HOME)/sw/workflow/.git ] || git clone http://github.com/genome/tgi-workflow.git -b gms-pub $(GMS_HOME)/sw/workflow
	[ -e $(GMS_HOME)/sw/rails/.git ] 		|| git clone http://github.com/genome/gms-webviews.git -b gms-pub $(GMS_HOME)/sw/rails 
	[ -e $(GMS_HOME)/sw/genome/.git ] 	|| git clone http://github.com/genome/gms-core.git -b gms-pub  $(GMS_HOME)/sw/genome	
	[ -e $(GMS_HOME)/sw/openlava/.git ] || git clone http://github.com/openlava/openlava.git -b 2.0-release $(GMS_HOME)/sw/openlava
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
	sudo chown -R genome:root /opt/openlava-2.0/work/  
	sudo chmod +x /etc/init.d/openlava
	sudo update-rc.d openlava defaults 98 02 || echo ...
	sudo cp setup/openlava-config/lsb.queues /opt/openlava-2.0/etc/lsb.queues
	cat setup/openlava-config/lsf.cluster.openlava | setup/bin/findreplace-gms >| /tmp/lsf.cluster.openlava
	sudo cp /tmp/lsf.cluster.openlava /opt/openlava-2.0/etc/lsf.cluster.openlava
	rm /tmp/lsf.cluster.openlava
	cd /etc; [ -e lsf.conf ] || ln -s ../opt/openlava-2.0/etc/lsf.conf lsf.conf
	(grep 127.0.1.1 /etc/hosts >/dev/null && sudo bash -c 'grep 127.0 /etc/hosts >> /opt/openlava-2.0/etc/hosts && setup/bin/findreplace localhost `hostname` /opt/openlava-2.0/etc/hosts') || true
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
	##cd /var/www/gms-webviews && sudo bundle install
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
	echo 'ServerName localhost' >> /tmp/gms-webviews.conf 
	echo 'ServerAlias some_hostname some_other_hostname' >> /tmp/gms-webviews.conf 
	echo 'DocumentRoot /var/www/gms-webviews/public' >> /tmp/gms-webviews.conf
	echo 'PassengerHighPerformance on' >> /tmp/gms-webviews.conf
	echo '<Directory /var/www/gms-webviews/public>' >> /tmp/gms-webviews.conf
	echo '  AllowOverride all' >> /tmp/gms-webviews.conf
	echo '  Options -MultiViews' >> /tmp/gms-webviews.conf
	echo '</Directory>' >> /tmp/gms-webviews.conf
	echo 'AddOutputFilterByType DEFLATE text/html text/css text/plain text/xml application/json' >> /tmp/gms-webviews.conf
	echo 'AddOutputFilterByType DEFLATE image/jpeg, image/png, image/gif' >> /tmp/gms-webviews.conf
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
	sudo bash -l -c 'source /etc/genome.conf; /usr/bin/perl setup/prime-allocations.pl'
	sudo bash -l -c 'source /etc/genome.conf; /usr/bin/perl setup/prime-sqlite.pl'
	sudo bash -l -c 'source /etc/genome.conf; ($(GMS_HOME)/sw/genome/bin/genome-perl $(GMS_HOME)/sw/genome/bin/genome disk volume list | grep reads >/dev/null)' 
	touch $@ 

done-host/db-driver: done-host/pkgs
	#
	# $@:
	# 
	# Install a newer DBD::Pg 
	# DBD::Pg as repackaged has deps which do not work with Ubuntu Precise.  This works around it.
	sudo -v
	[ `perl -e 'use DBD::Pg; print $$DBD::Pg::VERSION'` = '2.19.3' ] || sudo cpanm DBD::Pg


stage-software: done-host/pkgs done-host/git-checkouts done-repo/unzip-sw-apps-$(APPS_DUMP_VERSION).tgz done-repo/unzip-sw-java-$(JAVA_DUMP_VERSION).tgz 


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
	cd $(GMS_HOME)/sw/genome; git pull origin gms-pub
	cd $(GMS_HOME)/sw/ur; git pull origin gms-pub
	cd $(GMS_HOME)/sw/workflow; git pull origin gms-pub
	cd $(GMS_HOME)/sw/rails; git pull origin gms-pub
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
	setup/prime-allocations.pl
	sudo touch done-host/db-schema

apt-rebuild:
	# redo the apt configuration, which will download a new apt blob if necessary
	([ -e done-host/apt-config ] && rm done-host/apt-config) || true 
	make 'done-host/apt-config'

