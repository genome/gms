#!/usr/bin/env make

# NOTE: this makefile only works from within TGI to re-create the APT mirror

# used to name files
ifneq ("$(TIMESTAMP)", "")
  $(info using existing timestamp $(TIMESTAMP))
else
  TIMESTAMP=$(shell date +%Y.%m.%d)
  $(info timestamp $(TIMESTAMP))
endif

# this directory syncs to via cron https://xfer.genome.wustl.edu/gxfer1/project/gms/testdata/GMS1/setup/archive-files/
TGI_STAGING_DIR=/gscmnt/sata102/info/ftp-staging/pub/software/gms/setup/archive-files

all: mkmirror-$(TIMESTAMP) stage-tgi-$(TIMESTAMP) stage-s3-$(TIMESTAMP)

apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)/%:
	mkdir -p $@

mkmirror-$(TIMESTAMP): apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)/var apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)/skel apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)/mirror
	sudo apt-get install apt-mirror
	cat mirror-ubuntu-12.04.template | perl -ne 's|DIR|$(PWD)|; s|TIMESTAMP|$(TIMESTAMP)|; print' >| mirror-ubuntu-12.04-$(TIMESTAMP).config
	apt-mirror mirror-ubuntu-12.04-$(TIMESTAMP).config
	tgz apt-mirror-min-ubuntu-12.04-$(TIMESTAMP).tgz apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)
	mv apt-mirror-min-ubuntu-12.04-$(TIMESTAMP).tgz mirror-ubuntu-12.04-$(TIMESTAMP).config ../archive-files/ 
	rm -rf apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)
	touch $@

stage-tgi-$(TIMESTAMP): mkmirror-$(TIMESTAMP)
	rsync -avP ../archive-files/ $(TGI_STAGING_DIR) 
	touch $(TGI_STAGING_DIR)/../../syncme
	touch $@

stage-s3-$(TIMESTAMP): mkmirror-$(TIMESTAMP)
	echo "*** now use the aws command to sync ../archive-files with S3! ***"

