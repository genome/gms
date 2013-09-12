GMS
===

The Genome Modeling System *ALPHA*

_(this document is a work in progress and will not actually install as described, stay tuned for relese!!)_


Installation on Ubuntu 12.04
------------

For a standard, standalone, configuration on Ubuntu 12.04 run:

    sudo apt-get install git ssh make
    git clone https://github.com/genome/gms.git
    cd gms
    make


Installation on Mac OSX or Linux distributions other than Ubuntu 12.04
------------

Installation on another Linux system, or Mac OS X requires a VM, but the VM 
can be auto-installed if you have root access on the system.  For non-root, or for a 
Mac without Xcode installed, fall through to the Windows instructions below.

If you have root (or Xcode on a Mac), this will install VirtualBox and Vagrant.
It will download data to the working directory, but do final work on the VM using vagrant commands.

    git clone https://github.com/genome/gms.git
    cd gms
    make vminit     # install virtualbox and vagrant
    make vm         # install the system *inside* the VM

Assuming all went well you should now be able to log in as follows:

    vagrant ssh


Installation on Windows, or on Mac OS X without Xcode
-------------

All other systems, including Windows, VirtualBox (or another VM provider) can be installed manually.

VirtualBox can be downloaded here:

    https://www.virtualbox.org/wiki/Downloads

Download the correct ISO image for Ubuntu 12.04 (Precise)
Either the Desktop or Server versions will work.
    
    http://releases.ubuntu.com/precise/

Follow these instructions to install the image into VirtualBox:
    
    http://www.wikihow.com/Install-Ubuntu-on-VirtualBox

On your VM, follow the standard Ubuntu 12.04 directions above.

    sudo apt-get install git ssh make
    git clone https://github.com/genome/gms.git
    cd gms
    make
    

Installation on cloud servers
------------

For fancier things, like install on a cluster, edit the file "Vagrantfile", and use Amazon EC2 or OpenStack vagrant plugins.
Management of the cloud services can be done from any host that supports vagrant.  An upcoming release will offer more support
for managing the cluster.  For now Linux administration expertise and Vagrant expertise is required to make a cluster.

Initial Sanity Checks
-------------

    bjobs                   # You should not have any unfinished jobs yet
    bhosts                  # You should see one host ('precise64' if you are on a vagrant/virtualbox VM)
    bqueues                 # You should see four queues 
    genome disk group list  # You should see four disk groups
    genome disk volume list # You should see at least one volume for your local drive
    genoem sys gateway list # You should see one gateway for your new home system


Usage
-----

Attach the primary GMS provided by TGI for reference sequences, and example data:

    genome sys gateway attach GMS1


If you would prefer to copy the GMS1 data rather than mount it via FTP, use this:

    genome sys gateway attach GMS1 --rsync


To install the full set of example human cancer data, including reference sequences and annotation data sets:
    
    # import metadata
    genome model import metadata /opt/gms/GMS1/export/2891454740-2013.09.11.dat
  
    # list the models you just imported
    genome model list
    

To build the microarray models:

    genome model build start "name = 'tst1-tumor-snparray'"
    genome model build start "name = 'tst1-normal-snparray'"

To build the WGS tumor, WGS normal, exome tumor, and exome normal data, wait until the above finish, then run:
    
    genome model build start "name = 'tst1-tumor-wgs'"
    genome model build start "name = 'tst1-normal-wgs'"
    genome model build start "name = 'tst1-tumor-exome'"
    genome model build start "name = 'tst1-tumor-exome'"

While those are building, you can run the RNA-Seq models:

    genome model build start "name = 'tst1-tumor-rnaseq'"
    genome model build start "name = 'tst1-normal-rnaseq'"

To build the WGS somatic and exome somatic models, wait until the regular models above complete, and then run:

    genome model build start "name = 'tst1-somatic-wgs'"
    genome model build start "name = 'tst1-somatic-exome'"

When all of the above complete, the MedSeq pipeline can be run:

    genome model build start "name = 'tst1-clinseq'"

To monitor any build, run:

    genome model build view "id = '$BUILD_ID'"

To examine results, got to the build directory listead above, or list it specifically:

    genome model build list --filter "id = '$BUILD_ID'" --show id,data_directory


To import new data:

    cp /opt/gms/GMS1/export/example-samplesheet.tsv mysamplesheet.csv

    # edit the above with your favorite editor or spreadsheet
    # the first row is headers with column names
    # example columns: path, flow_cell_id, lane, index_sequence, target_region_set_name, library.name, individual.common_name, sample.common_name, sample.extraction_type
    # be sure to set individual.common_name to something like "patient1", or another identifier unique to your organization, but anonymized.
    # be sure to set sample.common_name to a value that distinguishes different samples for a patient, i.e.: "tumor", "normal", "relapse", "relapse 2", "metastasis" ...or just "sample 1"
    
    # import
    genome instrument-data import sample-sheet mysheet.tsv

    # list the things you just imported
    genome instrument-data list
    genome library list
    genome sample list 
    genome individual list
    genome taxon list


To make a new set of models for that data, this tool will walk you through the process interactively:

    # use the common name you used during import ("individual.common_name")
    genome model clin-seq update-analysis --individual "common_name = 'TST1'"


System Requirements
-------------------

System requirements for processing the example data through all pipelines:
 * 1TB for the results (40x WGS tumor/normal, 1 lane of exome, 1 lane of tumor RNA, processing through MedSeq)
 * 48+ GB of RAM
 * 12 cores
 * 2 weeks of processing time for full analysis (varies)



