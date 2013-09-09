#!/usr/bin/env make

# There are four stages to the make process
# 1. "stage_software": download more git repos and tarballs of software needed for install
# 2. "vminit": set up VMs as necessary (skipped if installing directly on the host)
# 3. "setup_env": configure core system things in /etc, set up user accounts, and change the environment
# 4. "setup": after setup_env, get a login shell and use the environment to complete installation

# "make" will perform 1, 3 and 4
# "make vm" will perform 1, 2, 3 and 4
# "make vars" will dump configuration information, and not build anything
# "make update-repos" can be used afterward to get the latest software
# "make db-rebuild" will re-create the database, empty, but primed for usage
# "make home" will initialize things for the current user to use the installed GMS

##### Configuration

# the identify of each GMS install is unique
# the subtraction causes the number width to grow over time slowly
GMS_ID:=$(shell cat /etc/genome/sysid 2>/dev/null)
ifeq ('$(GMS_ID)','') 
	GMS_ID:=$(shell ruby -e 'n=Time.now.to_i-1373561229; a=""; while(n > 0) do r = n % 36; a = a +  (r<=9 ? r.to_s : (55+r).chr); n=(n/36).to_i end; print a,sprintf("%02d",(rand()*100).to_i),"\n"')
endif
GMS_USER:='gms$(GMS_ID)'
GMS_GROUP:='gms$(GMS_ID)'

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

# data which is too big to fit in the git repository is staged here
DATASERVER=ftp://genome.wustl.edu/pub/software/gms/testdata/GMS1/setup/archive-files
#DATASERVER=ftp://clinus234/setup/archive-files

# the tool to use for bulk file transfer
FTP:=ftp
ifeq ('$(OS_VENDOR)','Ubuntu')
 FTP:=$(shell which ncftpget || (sudo apt-get install -q -y ncftp && which ncftpget))
endif

# this is empty for ftp/ncftp but is set to "." for scp and rsync
DOWNLOAD_TARGET=
ifeq ('$(FTP)', 'scp')
 	#DATASERVER=blade12-1-1:/gscmnt/sata102/info/ftp-staging/pub/software/gms/testdata/GMS1/setup/archive-files
 	#DATASERVER=clinus234:/opt/gms/GMS1/setup/archive-files
 	DOWNLOAD_TARGET:=.
endif

# when tarballs of software and data are updated they are given new names
APPS_DUMP_VERSION=2013-08-28
JAVA_DUMP_VERSION=2013-08-27
APT_DUMP_VERSION=20130906.120901

# other config info
IP:=$(shell /sbin/ifconfig | grep 'inet addr' | perl -ne '/inet addr:(\S+)/ && print $$1,"\n"' | grep -v 127.0.0.1)
HOSTNAME:=$(shell hostname)
PWD:=$(shell pwd)

# ensure the local directory is present for steps with results outside of the directory
$(shell [ -e `readlink done-local` ] || mkdir -p `readlink done-local`)

              
##### Primary Targets

# in a non-VM environment the default target "all" will build the entire system
all: sudo done-local/user-home-$(USER) stage-software 
	#
	# $@:
	#
	sudo -v
	DEBIAN_FRONTEND=noninteractive sudo make setup

# in a VM environment, the staging occurs on the host, and the rest on the VM
vm: sudo stage-software vminit
	#
	# $@:
	# log into the vm to finish the make process
	#
	sudo -v	
	vagrant ssh -c 'cd /vagrant && DEBIAN_FRONTEND=noninteractive sudo make setup'
	#
	# now run "vagrant ssh" to log into the new GMS
	#

sudo:
	sudo -v # sudo early to cache password (safely)

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



###### Core Steps

stage-software: done-shared/git-checkouts done-shared/unzip-sw-apps-$(APPS_DUMP_VERSION).tgz done-shared/unzip-sw-java-$(JAVA_DUMP_VERSION).tgz done-shared/unzip-sw-apt-mirror-min-ubuntu-12.04-$(APT_DUMP_VERSION).tgz 

setup_env: done-local/gms-home done-local/puppet 

setup: setup_env
	# nesting make ensures that the users and environment are set up before running things that depend on them
	sudo bash -l -c 'source /etc/genome.conf; make done-local/rails done-local/apache done-local/db-schema done-local/openlava-install'

##### Behind done-local/vminit: These steps are only run when setting up a VM host.

done-local/apt-get-update:
	#
	# $@:
	#
	sudo apt-get -y update 
	touch $@

done-local/vminstall-Ubuntu10.04:
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
	
done-local/vminstall-Ubuntu12.04:
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

done-local/vminstall-Darwin:
	#
	# $@:
	#
	sudo -v
	which VirtualBox || (cd setup/archive-files; curl -L http://download.virtualbox.org/virtualbox/4.2.16/VirtualBox-4.2.16-86992-OSX.dmg -o virtualbox.dmg && open virtualbox.dmg)
	while [[ ! `which VirtualBox` ]]; do echo "waiting for VirtualBox install to complete..."; sleep 3; done
	which vagrant || (cd setup/archive-files; curl -L http://files.vagrantup.com/packages/7ec0ee1d00a916f80b109a298bab08e391945243/Vagrant-1.2.7.dmg -o Vagrant.dmg && open Vagrant.dmg)
	while [[ ! `which vagrant` ]]; do echo "waiting for vagrant install to complete..."; sleep 3; done
	touch $@

done-local/vminstall: 
	#
	# $@:
	#
	sudo -v
	[ -e done-local/vminstall-$(OS) ] || sudo make done-local/vminstall-$(OS)
	(which VirtualBox && which vagrant && touch done-local/vminstall) || echo "**** run one of the following to auto-install for your platform: vminstall-mac, vminstall-10.04, or vminstall-12.04"
	which VirtualBox || (echo "**** you can install VirtualBox manually from https://www.virtualbox.org/wiki/Downloads")
	which vagrant || (echo "**** you can install vagrant manually from http://downloads.vagrantup.com/")

done-local/vmaddbox: done-local/vminstall
	#
	# $@:
	#
	# intializing vagrant (VirtualBox) VM...
	# these steps occur before the repo is visible on the VM
	#
	(vagrant box list | grep '^precise64' >/dev/null && echo "found vagrant precise64 box") || (echo "installing vagrant precise64 box" && vagrant box add precise64 http://files.vagrantup.com/precise64.box)
	touch $@

done-local/vmkernel:
	#
	# $@:
	#
	# intializing vagrant (VirtualBox) VM...
	# these steps occur before the repo is visible on the VM
	#
	sudo -v
	( (which apt-get >/dev/null) &&  ( [ -e `dpkg -L nfs-kernel-server | grep changelog` ] || sudo apt-get -y install -q -y nfs-kernel-server gcc ) ) || echo "nothing to do for Mac.."
	touch $@

vmcreate: done-local/vmaddbox done-local/vmkernel
	sudo -v
	#
	# the first bootup will fail because the NFS client is not installed 
	#
	vagrant up || true 
	#
	# fix the above issue by adding NSF to the client
	#
	vagrant ssh -c 'sudo apt-get update; sudo apt-get -y install -q - --force-yes nfs-client make'
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
	sudo -v
	vagrant ssh -c 'cd /vagrant &&  make done-local/vminit'

done-local/vminit:
	#
	# $@:
	# these steps can be done in parallel with stage-software
	#
	sudo -v
	sudo echo # cache password request
	make done-local/user-home-$(USER)
	make done-local/puppet 
	make done-local/sysid
	touch $@

# see "vm:" above for the final steps in a VM-based setup (i.e. run "sudo make setup" on the VM)

##### Behind "stage-software":

done-shared/git-checkouts:
	#
	# $@:
	#
	sudo -v
	[ -e sw/ur/.git ] 			|| git clone http://github.com/genome/UR.git -b gms-pub sw/ur
	[ -e sw/workflow/.git ] || git clone http://github.com/genome/tgi-workflow.git -b gms-pub sw/workflow
	[ -e sw/rails/.git ] 		|| git clone http://github.com/genome/gms-webviews.git -b gms-pub sw/rails 
	[ -e sw/genome/.git ] 	|| git clone http://github.com/genome/gms-core.git -b gms-pub  sw/genome	
	[ -e sw/openlava/.git ] || git clone http://github.com/openlava/openlava.git -b 2.0-release sw/openlava
	touch $@

# downloading and unzipping are all done with generic targets
# ...except one that requires special rename handling


done-shared/download-%: 
	#
	# $@:
	#
	sudo -v
	cd setup/archive-files; $(FTP) $(DATASERVER)/`basename $@ | sed s/download-//` $(DOWNLOAD_TARGET)
	touch $@

done-shared/unzip-sw-%: done-shared/download-% 
	#
	# $@:
	#
	sudo -v
	tar -zxvf setup/archive-files/`basename $< | sed s/download-//` -C sw
	touch $@ 

done-shared/unzip-fs-%: done-shared/download-%
	#
	# $@:
	#
	sudo -v
	tar -zxvf setup/archive-files/`basename $< | sed s/download-//` -C fs 
	touch $@ 

done-shared/unzip-sw-apps-$(APPS_DUMP_VERSION).tgz: done-shared/download-apps-$(APPS_DUMP_VERSION).tgz
	#
	# $@:
	# unzip apps which are not packaged as .debs (publicly available from other sources)
	#
	sudo -v
	tar -zxvf setup/archive-files/apps-$(APPS_DUMP_VERSION).tgz -C sw
	cd sw/apps && ln -s ../../sw/apps-$(APPS_DUMP_VERSION)/* . || true
	touch $@ 


##### Between staging of files and running setup, or to be run by any user after:

done-local/user-home-%:
	#
	# $@: 
	# copying configuration into the current user's home directory
	# re-run "make home" for any new user...
	#
	sudo -v
	[ `basename $(USER_HOME)` = `basename $@ | sed s/user-home-//` ]
	cp $(PWD)/setup/home/.??* $(USER_HOME)
	touch $@

##### Behind "setup_env": run as root

done-local/sysid: 
	#
	# $@:
	# setup /etc/genome/sysid if it is not present
	# and if it is present verify that it agress with the make variable
	#
	sudo -v
	[ -e /etc/genome/ ] || sudo mkdir /etc/genome
	sudo chmod go-w /etc/genome
	[ -z /etc/genome/sysid ] || sudo bash -c 'echo '$(GMS_ID)' > /etc/genome/sysid'
	# expected sysid is $(GMS_ID)
	cat /etc/genome/sysid
	test "`cat /etc/genome/sysid`" = '$(GMS_ID)' 
	touch $@

done-local/hosts:
	#
	# $@:
	#
	sudo -v
	echo "$(IP) GMS_HOST" | setup/bin/findreplace-gms | sudo bash -c 'cat - >>/etc/hosts'
	touch $@ 

done-local/puppet: done-local/sysid done-local/hosts
	#
	# $@:
	# the bridge over to puppet-based install
	#
	sudo -v
	which puppet || sudo apt-get -q -y install puppet # if puppet is already installed do NOT use apt, as the local version might be independent
	bash -l -c 'sudo puppet apply manifests/$(MANIFEST)'
	touch $@

done-local/gms-home: done-local/puppet 
	#
	# $@:
	#
	sudo -v
	[ -d "$(GMS_HOME)" ] || sudo mkdir -p "$(GMS_HOME)"
	echo GMS_HOME is $(GMS_HOME)
	cat setup/dirs | sudo xargs -n 1 -I DIR bash -c 'cd $(GMS_HOME); mkdir -p DIR; sudo chown genome:genome DIR; sudo chmod g+sw DIR'
	[ "`readlink $(GMS_HOME)/sw`" = "$(PWD)/sw" ] || (sudo rm "$(GMS_HOME)/sw" 2>/dev/null; sudo ln -s $(PWD)/sw "$(GMS_HOME)/sw")
	[ "`readlink $(GMS_HOME)/fs`" = "$(PWD)/fs" ] || (sudo rm "$(GMS_HOME)/fs" 2>/dev/null; sudo ln -s $(PWD)/fs "$(GMS_HOME)/fs")
	[ "`readlink $(GMS_HOME)/db`" = "$(PWD)/db" ] || (sudo rm "$(GMS_HOME)/db" 2>/dev/null; sudo ln -s $(PWD)/db "$(GMS_HOME)/db")
	[ -d "$(GMS_HOME)/export" ] || mkdir "$(GMS_HOME)/export"
	[ -d "$(GMS_HOME)/known-systems" ] || mkdir "$(GMS_HOME)/known-systems"
	cp known-systems/* "$(GMS_HOME)/known-systems"
	touch $(GMS_HOME)/export/sanitize.csv
	#sudo mkdir -p $(GMS_HOME)/fs/$(GMS_ID)
	#sudo ln -s $(PWD)/fs/* "$(GMS_HOME)/fs/$(GMS_ID)"
	touch $@

done-local/apt-config: done-local/puppet done-shared/unzip-sw-apt-mirror-min-ubuntu-12.04-$(APT_DUMP_VERSION).tgz
	#
	# $@:
	# done-local/apt-config:
	# configure apt to use the GMS repository
	#
	sudo -v
	sudo dpkg --force-confdef --force-confnew -i sw/apt-mirror-min-ubuntu-12.04-$(APT_DUMP_VERSION)/mirror/repo.gsc.wustl.edu/ubuntu/pool/main/g/genome-apt-config/genome-apt-config_1.0.0-2~Ubuntu~precise_all.deb
	/bin/cp setup/debconf.in /tmp
	# findreplace WHATEVER /tmp/debconf.in
	sudo debconf-set-selections < /tmp/debconf.in
	touch $@	

done-local/etc: done-local/apt-config 
	#
	# $@:
	# copy all data from setup/etc into /etc
	# 
	sudo -v
	/bin/ls setup/etc/ | perl -ne 'chomp; $$o = $$_; s|\+|/|g; $$c = "cp setup/etc/$$o /etc/$$_\n"; print STDERR $$c; print STDOUT $$c' | sudo bash
	sudo setup/bin/findreplace REPLACE_GENOME_HOME $(GMS_HOME) /etc/genome.conf /etc/apt/sources.list.d/genome.list
	sudo setup/bin/findreplace REPLACE_GENOME_SYS_ID $(GMS_ID) /etc/genome.conf /etc/apt/sources.list.d/genome.list
	sudo setup/bin/findreplace REPLACE_APT_DUMP_VERSION $(APT_DUMP_VERSION) /etc/apt/sources.list.d/genome.list
	sudo bash -c 'echo "/opt/gms/$(GMS_ID) *(ro,anonuid=2001,anongid=2001)" >> /etc/exports'	
	touch $@

done-local/pkgs: done-local/etc
	#
	# $@:
	#
	sudo -v
	# update from the local apt mirror directory
	sudo apt-get update >/dev/null 2>&1 || true  
	# install primary dependency packages 
	sudo apt-get install -q -y --force-yes git-core vim nfs-common perl-doc genome-snapshot-deps `cat setup/packages.lst`
	# install rails dependency packages
	sudo apt-get install -q -y --force-yes git ruby1.9.1 ruby1.9.1-dev rubygems1.9.1 irb1.9.1 ri1.9.1 rdoc1.9.1 build-essential apache2 libopenssl-ruby1.9.1 libssl-dev zlib1g-dev libcurl4-openssl-dev apache2-prefork-dev libapr1-dev libaprutil1-dev postgresql postgresql-contrib libpq-dev libxslt-dev libxml2-dev genome-rails-prod
	# install unpackaged Perl modules
	[ -e setup/bin/cpanm ] || (curl -L https://raw.github.com/miyagawa/cpanminus/master/cpanm >| setup/bin/cpanm && chmod +x setup/bin/cpanm)
	sudo setup/bin/cpanm Getopt::Complete
	touch $@

### behind "setup", after "setup_env"

done-local/openlava-compile: done-shared/git-checkouts done-local/hosts done-local/etc done-local/pkgs
	#
	# $@:
	#
	sudo -v
	cd sw/openlava && ./bootstrap.sh && make && make check && sudo make install 
	touch $@

done-local/openlava-install: done-local/openlava-compile
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
	grep 127.0.1.1 /etc/hosts >/dev/null && sudo bash -c 'grep 127.0 /etc/hosts >> /opt/openlava-2.0/etc/hosts && setup/bin/findreplace localhost `hostname` /opt/openlava-2.0/etc/hosts'
	sudo /etc/init.d/openlava start || sudo /etc/init.d/openlava restart
	sudo /etc/init.d/openlava status
	touch $@

done-local/db-init: done-local/pkgs 
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

done-local/rails: done-local/pkgs
	#
	# $@:
	# 
	sudo -v
	sudo gem install bundler --no-ri --no-rdoc --install-dir=/var/lib/gems/1.9.1
	sudo chown www-data:www-data /var/www
	sudo -u www-data rsync -r sw/rails/ /var/www/gms-webviews
	##cd /var/www/gms-webviews && sudo bundle install
	[ -e /var/www/gms-webviews/tmp ] || sudo -u www-data mkdir /var/www/gms-webviews/tmp
	sudo -u www-data touch /var/www/gms-webviews/tmp/restart.txt
	touch $@

done-local/apache: done-local/pkgs 
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
	touch $@

done-local/db-schema: done-local/db-init done-local/hosts
	#
	# $@:
	# 
	sudo -v
	sudo -u postgres psql -d genome -f setup/schema.psql	
	sudo bash -l -c 'source /etc/genome.conf; /usr/bin/perl setup/prime-allocations.pl'
	sudo bash -l -c 'source /etc/genome.conf; (sw/genome/bin/genome-perl sw/genome/bin/genome disk volume list | grep reads >/dev/null)' 
	touch $@ 

done-local/db-driver: done-local/pkgs
	#
	# $@:
	# 
	# Install a newer DBD::Pg 
	# DBD::Pg as repackaged has deps which do not work with Ubuntu Precise.  This works around it.
	sudo -v
	[ `perl -e 'use DBD::Pg; print $$DBD::Pg::VERSION'` = '2.19.3' ] || sudo cpanm DBD::Pg


##### Optional maintenance targets:

home: done-local/user-home-$(USER)
	#
	# $@:
	#
	sudo -v
	
update-repos:
	#
	# $@:
	#
	sudo -v
	cd sw/genome; git pull origin gms-pub
	cd sw/ur; git pull origin gms-pub
	cd sw/workflow; git pull origin gms-pub
	cd sw/rails; git pull origin gms-pub
	[ -d /var/www/gms-webviews ] || sudo mkdir /var/www/gms-webviews
	sudo chown -R www-data:www-data /var/www/gms-webviews/
	sudo -u www-data rsync -r sw/rails/ /var/www/gms-webviews
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
	touch done-local/db-schema

apt-rebuild:
	# redo the apt configuration, which will download a new apt blob if necessary
	([ -e done-local/apt-config ] && rm done-local/apt-config) || true 
	make 'done-local/apt-config'


