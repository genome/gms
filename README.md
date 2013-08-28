GMS
===

The Genome Modeling System ALPHA

(this document is a work in progress and will not actually install as described)


Download
--------

This software suite is available on github via clone:

  git clone git@github.com:genome/gms.git 
  cd gms


Installation on Ubuntu 12.04
------------

For a standard, standalone, configuration on Ubuntu 12.04 run:
  
    make


Installation on Mac OSX or Linux distributions other than Ubuntu 12.04
------------

For a VM using VirtualBox and Vagrant, run the following on the HOST, which can be any POSIX system (Mac, other Linux).
It will download data to the working directory, but do final work on the VM using vagrant commands.

    make vm

Assuming all went well you should now be able to log in as follows:

    vagrant ssh


Installation on Windows
-------------

Install Ubuntu 12.04 via virtualbox.  From within the VM, follow the Ubuntu 12.04 instructions above.


Installation on cloud servers
------------

For fancier things, like install on a cluster, edit the file "Vagrantfile", and use Amazon EC2 or OpenStack vagrant plugins.
Management of the cloud services can be done from any host that supports vagrant.

Usage
-----

Attach the primary GMS provided by TGI for referen sequences an examples:

    genome sys peer attach GMS1

To install the full set of example human cancer data:
    
    genome model import metadata --source GMS1 --data-set examples/human-cancer.dat
    genome model build start "name = 'TST1.clin_seq'" --recurse


To just install the reference data for human samples:

    genome model import metadata --source GMS1 --data-set refdata/human.dat

To import new data:

    vim SAMPLESHEET
    # example columns: flow_cell_id, lane, index, fastq1, fastq2, bam, bcf, sample.name, sample.common_name, patient.name, patient.common_name, sample.tissue_desc, 
    
    genome instrument-data import illumina-ngs SAMPLESHEET
    genome model define clin-seq --name patient1-analysis1 



System Requirements
-------------------

System requirements for processing the example data through all pipelines:
 * 1TB for the results
 * 48+ GB of RAM
 * 12 cores
 * 2 weeks of processing time for full analysis (varies)

To import your own data:

    genome instrument-data import -h

To configure analysis:

    genome model clin-seq update-analysis -h


