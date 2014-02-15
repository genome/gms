GMS
===

The Genome Modeling System (GMS) **ALPHA**

A paper describing the GMS is under preparation.

Some of the tools made available through the GMS have been previously released as <a href="http://gmt.genome.wustl.edu/">Genome Modeling Tools</a>

The raw data and reference files needed for the tutorial below are made available through our <a href="http://genome.wustl.edu/pub/software/gms/testdata/">FTP</a> and as an <a href="https://gmsdata.s3.amazonaws.com/">Amazon Public Dataset</a>


Installation on Ubuntu 12.04
------------

For a standard, standalone, configuration on Ubuntu 12.04 run:

```bash
sudo apt-get install git ssh make
git clone https://github.com/genome/gms.git
cd gms
make
```

Once the installation completes make sure to log out and log in again to ensure your user permissions are set properly.


Installation on Mac OS X, Linux distributions other than Ubuntu 12.04, or other POSIX systems:
------------

Installation on another platform requires a virtual machine (VM).  On a POSIX system that supports vagrant
a Vagrant/VirtualBox install can be automaticaly performed.  The provides advantages over the third option
below, usable on Windows, because the Vagrant configuration can be extended to manage a whole cluster
on Amazon, OpenStack, VMWare, etc. 

NOTE: You must have sudo access on the host machine to use this option.

NOTE: You must install git, ssh, and make on your system before doing the following.

This is the recommended approach for running on Mac OS X.  Be sure to install Xcode first.

```bash
git clone https://github.com/genome/gms.git
cd gms
make vminit     # install virtualbox and vagrant, and an Ubuntu 12.04 VM
vagrant ssh     # log into the VM
make            # install the gms
```

Once the virtual machine is created successfully if you want to reboot the host system, you should
log out of the VM and use 'vagrant suspend' to shutdown the VM, then 'vagrant resume' to reboot it.


Installation on Windows, on Mac OS X without Xcode, or any other system that supports virtual machines:
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

```bash
sudo apt-get install git ssh make
git clone https://github.com/genome/gms.git
cd gms
make
```

Once the installation completes make sure to log out and log in again to ensure your user permissions are set properly.


Installation on cloud servers
------------

For more complex configurations, like install on a cluster or cloud servers, edit the file "Vagrantfile", and use Amazon EC2 or OpenStack vagrant plugins.
Management of the cloud services can be done from any host that supports vagrant.

An upcoming release will offer more support for managing the cluster.

For now Linux administration expertise and Vagrant expertise is required to make a cluster.  This system runs 
daily on a 4000 node cluster with 15PB of network attached storage at The Genome Institute.  Scalability beyond
this point has not been measured.


Initial Sanity Checks
-------------

The following checks can be made after logging into the GMS:

```bash
lsid                      # You should see the openlava cluster identification
lsload                    # You should see a report of available resources
bjobs                     # You should not have any unfinished jobs yet
bsub 'sleep 60'           # You should be able to submit a job to openlava (run bjobs again to see it)
bhosts                    # You should see one host
bqueues                   # You should see four queues
genome disk group list    # You should see four disk groups
genome disk volume list   # You should see at least one volume for your local drive
genome sys gateway list   # You should see two gateways, one for your new home system and one for the test data "GMS1"
```

Your New System:
-------------

Each GMS has a unique ID:

```bash
cat /etc/genome/sysid
echo $GENOME_SYS_ID
```

The entire installation lives in a directory with the ID embedded:

```bash
echo $GENOME_HOME # /opt/gms/$GENOME_SYS_ID
```

The initial system has one node, and that node has only its local disk on which to perform analysis.  
To expand the system to multiple nodes, add disks, or use network-attached storage, see the secion below
System Expansion.


Usage
-----

To install the full set of example human cancer data, including reference sequences and annotation data sets:

```bash
# download
wget http://genome.wustl.edu/pub/software/gms/testdata/GMS1/export/18177dd5eca44514a47f367d9804e17a-2014.1.16.dat
    
# import
genome model import metadata 18177dd5eca44514a47f367d9804e17a-2014.1.16.dat
  
# list the data you just imported
genome taxon list
genome individual list
genome sample list
genome library list
genome instrument-data list solexa
    
# list the pre-defined models (no results yet ... you will launch these and generate results)
genome model list
    
# list the processing profiles associated with those models
genome processing-profile list reference-alignment
genome processing-profile list somatic-variation
genome processing-profile list rna-seq
genome processing-profile list differential-expression    
genome processing-profile list clin-seq
```

You now have metadata about reads from GMS1 in your system, but no access to the real underlying 
files (reads, alignments, variant calls).

This will allow you to attach GMS1 disks so you can process the data.

```bash
genome sys gateway attach GMS1
```

The above will mount GMS1 data on your system at /opt/gms/GMS1.

If you would prefer to have a local copy the GMS1 data rather than mount it via FTP (highly recommended), use this:
**WARNING**: This data set is 385 GB.  It may consume considerable bandwidth and be very slow to install.

```bash
genome sys gateway attach GMS1 --protocol ftp --rsync
```

To build the genotype microarray models:

```bash
genome model build start "name='hcc1395-normal-snparray'"
genome model build start "name='hcc1395-tumor-snparray'"
```

To build the WGS tumor, WGS normal, exome tumor, and exome normal data, wait until the above finish, then run:

```bash
genome model build start "name='hcc1395-normal-refalign-exome'"
genome model build start "name='hcc1395-tumor-refalign-exome'"
genome model build start "name='hcc1395-normal-refalign-wgs'"
genome model build start "name='hcc1395-tumor-refalign-wgs'"
```

While those are building, you can run the RNA-Seq models:

```bash
genome model build start "name='hcc1395-normal-rnaseq'"
genome model build start "name='hcc1395-tumor-rnaseq'"
```

To build the WGS somatic and exome somatic models, wait until the ref-align models above complete, and then run:

```bash
genome model build start "name='hcc1395-somatic-exome'"
genome model build start "name='hcc1395-somatic-wgs'"
```

To build the differential expression models, wait until the rna-seq models above complete, and then run:

```bash
genome model build start "name='hcc1395-differential-expression'"
```

When all of the above complete, the MedSeq pipeline can be run:

```bash
genome model build start "name='hcc1395-clinseq'"
```

To view the inputs to any model, you can do something like the following:

```bash
genome model input show --model="hcc1395-clinseq"
```

To view the status of all builds, run:

```bash
genome model build list
```

To monitor progress of any particular build, run:

```bash
genome model build view "id='$BUILD_ID'"
```

To examine results, go to the build directory listed above, or list it specifically:

```bash
genome model build list --filter "id='$BUILD_ID'" --show id,data_directory
```

To import new data:

    *sample importer coming soon*

To make a new set of models for that data once imported, this tool will walk you through the process interactively:

```bash
# use the common name you used during import ("individual.common_name")
genome model clin-seq update-analysis --individual "common_name = 'TST1'"
```

System Requirements
-------------------

System requirements for processing the example data through all pipelines:
 * 100 GB for reference-related data used by pipelines
 * 284 GB for test data
 * 1 TB for the results (40x WGS tumor/normal, 1 lane of exome, 1 lane of tumor RNA, processing through MedSeq)
 * 1 TB of /tmp space 
 * 48+ GB of RAM
 * 12+ cores
 * 2 weeks of processing time for full analysis (varies)

One of the systems we used for testing the GMS from within a Virtual Machine looked like this: Mac Pro, Mid 2010, 2 x 2.4 GHz Quad-Core Intel Xeon, 64 GB 800 MHz DDR3 ECC, and three 2TB SATA drives.

   
Security
--------

The GMS presumes that _other_ GMS installations are _untrusted_ by default, and that users on the _same_ GMS are _trusted_ 
by default.  This allows each installation to make decisions about the balance of security and convenience as suits its
needs, and to change those decisions over time.

Independent GMS installations lean entirely on standard Unix/Linux permissions and sharing facilities (SSH, NFS, etc.), 
and are as secure as those facilities.  Another GMS cannot access your data any more than a random user on the internet 
could, but the system is configured to allow sharing to be as convienient and granular as the adminstrators prefer later.

Within a GMS instance, all users are in a single Unix group, and all directories are writable by that group.  If 
a given group of users cannot be trusted to this level, it is best to install independent systems, and use the
"federation" facilities to control sharing.  In the native environment of the GMS at Washington University, The Genome 
Institute uses one system for a staff of several hundred (combining programmers, analysts and laboratory staff), and 
with isolated instances in preparation only for medical diagnostics.

In a hierarchical organization, a group of individual GMS installations can export metadata to a larger GMS, without 
copying it, providing centralization of metadata, while distributiong load, and keeping data in cost centers.

At its most extreme, in an environment that requires per-user security, each user could install a GMS independently, 
and use the "federation" capabilities to attach the systems of co-workers, share data, and peform larger scale analysis
entirely within that framework. 


System Expansion (under development)
------------
Step 1.  Add a host to the network running Ubuntu 12.04
Step 2.  Ensure you can log into the remote matchine with ssh without a password, and can sudo
Step 3.  On the original machine, run this: genome sys node add $IP ##FIXME: not pushed

To work with expanding the system beyond one node:

```bash
genome sys node list    ##FIXME not pushed
genome sys node add     ##FIXME not pushed
genome sys node remove  ##FIXME not pushed
```

To make the GMS aware of disk at a given mount point:

```bash
genome disk volume list
genome disk volume attach               ##FIXME not pushed
genome disk volume detach               ##FIXME not pushed
genome disk volume disable-allocation   ##FIXME not pushed
genome disk volume enable-allocation    ##FIXME not pushed
```

To attach/detach other systems:

```bash
genome sys gateway list
genome sys gateway attach
genome sys gateway detach
```

Because the system always uses unique paths, data across systems can be federated easily.  No path to any
data you generate will match the path anyone else uses, allowing mounting and copying of data to occur without collisions.

There is a special GMS user and group on every system, with a name like gms$GENOME_SYS_ID

```bash
finger gms$GENOME_SYS_ID ##FIXME: still using the genome user
groups gms$GENOME_SYS_ID ##FIXME: still using the genome group
```

All users on a given GMS installation will also be members of the above group.

To do this for new users beyond the user that installs the system, run:

```bash
genome sys user init ##FIXME: not pushed
```

When other GMS installations give your installation permissions, they will add a user with that name 
and give permissions to that user.  When you attach their systems, you will do so as that user, and
their data will, conversely, be owned by the matching user on your system. 
