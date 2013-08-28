#!/usr/bin/env make

# if changed to a new value, /opt/gms will be a symlink to this value 
# (some code below depends on a hard-coded path and uses /opt/gms during installation sadly)
GMS_HOME=/opt/gms

EXAMPLE_CLINSEQ_MODEL_ID=2891454740

# used to name files
ifneq ("$(TIMESTAMP)", "")
  $(info using existing timestamp $(TIMESTAMP))
else
  TIMESTAMP=$(shell date +%Y%m%d.%H%m%S)
  $(info timestamp $(TIMESTAMP))
endif


# data which is too big to fit in the git repository is staged here
#DATASERVER=ftp://genome.wustl.edu:/pub/software/gms/setup/archive-files
STAGING_DIR=/gscmnt/sata102/info/ftp-staging/pub/software/gms/download

# steps which use this path will only work from within TGI

all: sw data

sw: apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)/var apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)/skel apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)/mirror
	sudo apt-get install apt-mirror
	cat mirror-ubuntu-12.04.template | perl -ne 's|DIR|$(PWD)|; s|TIMESTAMP|$(TIMESTAMP)|; print' >| mirror-ubuntu-12.04-$(TIMESTAMP).config
	apt-mirror mirror-ubuntu-12.04-$(TIMESTAMP).config
	tgz apt-mirror-min-ubuntu-12.04-$(TIMESTAMP).tgz apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)
	mv apt-mirror-min-ubuntu-12.04-$(TIMESTAMP).tgz mirror-ubuntu-12.04-$(TIMESTAMP).config tmp/ 
	rm -rf apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)

apt-mirror-min-ubuntu-12.04-$(TIMESTAMP)/%:
	mkdir -p $@

data: refdata example-big example-medium 

refdata:
	cd tmp; ../dump-db.pl --refdata Genome::Model $(EXAMPLE_CLINSEQ_MODEL_ID) >| refdata-$(TIMESTAMP).dat

example-big: export-2891454740

example-medium: export-2891407507

example-small:
	# TODO downsample the exome!
	
###

export-%: 
	cd tmp; ../dump-db.pl Genome::Model `echo $@ | sed s/export-//` 1>export-db-`echo $@ | sed s/export-//`.$(TIMESTAMP).dat 2>/dev/null
	cd tmp; ../summarize-disk.pl dump-db-`echo $@ | sed s/export-//`.$(TIMESTAMP).out 1>summarize-disk-`echo $@ | sed s/export-//`.$(TIMESTAMP).dat 2>/dev/null

stage: 
	mv tmp/* $(STAGING_DIR)/


