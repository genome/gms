#!/usr/bin/env make

# used to name files
ifneq ("$(TIMESTAMP)", "")
  $(info using existing timestamp $(TIMESTAMP))
else
  TIMESTAMP=$(shell date +%Y-%m-%d)
  $(info timestamp $(TIMESTAMP))
endif


# data which is too big to fit in the git repository is staged here
#DATASERVER=ftp://genome.wustl.edu:/pub/software/gms/setup/archive-files
STAGING_DIR=/gscmnt/sata102/info/ftp-staging/pub/software/gms/download

# steps which use this path will only work from within TGI

all: apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)/var apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)/skel apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)/mirror
	sudo apt-get install apt-mirror
	cat mirror-ubuntu-12.04.template | perl -ne 's|DIR|$(PWD)|; s|TIMESTAMP|$(TIMESTAMP)|; print' >| mirror-ubuntu-12.04-$(TIMESTAMP).config
	apt-mirror mirror-ubuntu-12.04-$(TIMESTAMP).config
	tgz apt-mirror-min-ubuntu-12.04-$(TIMESTAMP).tgz apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)
	mv apt-mirror-min-ubuntu-12.04-$(TIMESTAMP).tgz mirror-ubuntu-12.04-$(TIMESTAMP).config tmp/ 
	rm -rf apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)

apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)/%:
	mkdir -p $@


