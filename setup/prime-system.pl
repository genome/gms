#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

my $usage=<<INFO;

./prime-system.pl --data=hcc1395_1tenth_percent --sync=tarball 

Arguments:
--data          data set to download ('hcc1395', 'hcc1395_1percent', 'hcc1395_1tenth_percent', 'none')
--sync          syncing method ('rsync', 'tarball')
--help          display this documentation

INFO

my $data = '';
my $sync = '';
my $help = '';

GetOptions ('data=s'=>\$data, 'sync=s'=>\$sync, 'help'=>\$help);

if ($help || !$data || !$sync){
  print "$usage";
  exit();
}
unless ($data =~ /^hcc1395$|^hcc1395_1percent$|^hcc1395_1tenth_percent$|^none$/){
  print "\n\nMust specify a valid value for --data: 'hcc1395', 'hcc1395_1percent', 'hcc1395_1tenth_percent', 'none'\n\n";
  exit();
}
unless ($sync =~ /^rsync$|^tarball$/){
  print "\n\nMust specify a valid value for --sync: 'tarball', 'rsync'\n\n";
  exit();
}

#Put the latest metadata filename here:
my $metadata_file = "18177dd5eca44514a47f367d9804e17a-2014.3.14.dat";
my $export_url = "https://xfer.genome.wustl.edu/gxfer1/project/gms/testdata/GMS1/export/";
my $metadata_url = $export_url . $metadata_file; 

#Download meta-data .dat file
unless (-e $metadata_file){
  my $wget_cmd = "wget $metadata_url";
  print "\n\nRUN: $wget_cmd\n";
  system($wget_cmd);
}

#Import the meta-data using 'genome model import metadata'
#File based databases from github will also be installed during this step
my $import_cmd = "genome model import metadata $metadata_file";
print "\n\nRUN: $import_cmd\n";
system($import_cmd);

#Sync data either by using `genome sys gateway attach GMS1` or simply by getting a GMS1.tgz and unpacking it
if ($sync eq 'rsync'){
  #Sync GMS1 using `genome sys gateway attach GMS1 --protocol ftp --rsync` or unpacking on a single tarball
  my $sync_cmd = "genome sys gateway attach GMS1 --protocol ftp --rsync";
  print "\n\nRun: $sync_cmd\n";
  system($sync_cmd);
}elsif($sync eq 'tarball'){
  #Sync GMS1 by obtaining a GMS1.tgz, unpacking it and creating a symlink

}


#Download the separate batch of BAM files indicated by the user and store in /opt/gms/bams


#Move these files into the places expected by the metadata dump
#TODO: replace with import of these BAMs using the sample importer


#Make sure the /opt/gms/GMS1 symlink is in place


#Perform some automatic sanity checks of the system and report problems to the user


exit;
