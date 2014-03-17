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

#Make sure the user is within the sGMS, install has been run and ENVs are set by checking for $GENOME_SYS_ID
unless ($ENV{GENOME_SYS_ID}){
  print "\n\nGENOME_SYS_ID is not set!  Are you logged in and the installation is complete?\n\n";
  exit();
}
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
  print "\n\nRUN: $sync_cmd\n";
  system($sync_cmd);
}elsif($sync eq 'tarball'){
  #Sync GMS1 by obtaining a GMS1.tgz, unpacking it and creating a symlink
  my $tarname = "GMS1.tgz";
  my $tarball = "/opt/gms/$tarname";
  my $tardir = "/opt/gms/.GMS1.tarball/";
  if (-e $tarball || -e $tardir){
    print "\n\nWARNING: $tarball and/or $tardir are already present, delete these if you want to download GMS1 from scratch\n";
  }else{
    #Get the GMS1 tarball
    my $gms1_lftp_cmd = "
    lftp -c \"set ftp:list-options -a; 
    set mirror:parallel-directories true; 
    set ftp:use-mdtm false; 
    set net:limit-rate 0; 
    open 'ftp://xfer.genome.wustl.edu'; 
    lcd /opt/gms/;
    cd gms/testdata;
    get $tarname\"";
    print "\n\nRUN: $gms1_lftp_cmd\n";
    system($gms1_lftp_cmd);

    #Unpack the GMS1 tarball to /opt/gms/.GMS1.tarball
    my $unpack_cmd = "mkdir $tardir; mv $tarball $tardir; cd $tardir; tar -zxvf $tardir/$tarname";
    print "\n\nRUN: $unpack_cmd\n";
    system($unpack_cmd);

    #Move contents of the unpacked tarball up a level
    my $mv_cmd = "mv $tardir"."GMS1/* $tardir";
    print "\n\nRUN: $mv_cmd\n";
    system($mv_cmd);
    
    #Create the GMS1 symlink
    my $symlink_cmd = "cd /opt/gms; rm -f /opt/gms/GMS1; ln -s /opt/gms/.GMS1.tarball GMS1";
    print "\n\nRUN: $symlink_cmd\n";
    system($symlink_cmd);

    #Clean up
    my $rm_cmd = "rm -fr $tardir"."$tarname $tardir"."GMS1";
    print "\n\nRUN: $rm_cmd\n";
  }
}

#Download the separate batch of BAM files indicated by the user and store in /opt/gms/bams
unless ($data eq "none"){
  my $bam_list = "gerald_D1VCPACXX_6.bam gerald_D1VCPACXX_7.bam gerald_D1VCPACXX_8.bam gerald_D1VCPACXX_1.bam gerald_D1VCPACXX_2.bam gerald_D1VCPACXX_3.bam gerald_D1VCPACXX_4.bam gerald_D1VCPACXX_5.bam gerald_C1TD1ACXX_7_CGATGT.bam gerald_C1TD1ACXX_7_ATCACG.bam gerald_C2DBEACXX_3.bam gerald_C1TD1ACXX_8_ACAGTG.bam";
  my $bam_base_dir = '/opt/gms/bams/';
  mkdir $bam_base_dir unless (-e $bam_base_dir);
  my $bam_dir = $bam_base_dir . $data . "/";
  mkdir $bam_dir unless (-e $bam_dir);
  my $bam_lftp_cmd = "
  lftp -c \"set ftp:list-options -a;
  set mirror:parallel-directories true;
  set ftp:use-mdtm false;
  set net:limit-rate 0; 
  open 'ftp://xfer.genome.wustl.edu';
  lcd $bam_dir; 
  cd gms/testdata/bams/$data/; 
  get $bam_list\"";
  print "\n\nRUN: $bam_lftp_cmd\n";
  system($bam_lftp_cmd);

  #Move these files into the places expected by the metadata dump
  #TODO: replace with import of these BAMs using the sample importer
  my $op = "cp -f";
  $op = "mv -f" if ($data eq "hcc1395");
  my $bam_base = "/opt/gms/bams";
  my $fs_base = "/opt/gms/GMS1/fs/gc6001/production";

  my $mv_cmd1 = "$op $bam_base/$data/gerald_D1VCPACXX_6.bam $fs_base/csf_135291690/gerald_D1VCPACXX_6.bam";
  my $mv_cmd2 = "$op $bam_base/$data/gerald_D1VCPACXX_7.bam $fs_base/csf_135292156/gerald_D1VCPACXX_7.bam";
  my $mv_cmd3 = "$op $bam_base/$data/gerald_D1VCPACXX_8.bam $fs_base/csf_135291998/gerald_D1VCPACXX_8.bam";
  my $mv_cmd4 = "$op $bam_base/$data/gerald_D1VCPACXX_1.bam $fs_base/csf_135293260/gerald_D1VCPACXX_1.bam";
  my $mv_cmd5 = "$op $bam_base/$data/gerald_D1VCPACXX_2.bam $fs_base/csf_135290829/gerald_D1VCPACXX_2.bam";
  my $mv_cmd6 = "$op $bam_base/$data/gerald_D1VCPACXX_3.bam $fs_base/csf_135290878/gerald_D1VCPACXX_3.bam";
  my $mv_cmd7 = "$op $bam_base/$data/gerald_D1VCPACXX_4.bam $fs_base/csf_135291736/gerald_D1VCPACXX_4.bam";
  my $mv_cmd8 = "$op $bam_base/$data/gerald_D1VCPACXX_5.bam $fs_base/csf_135294298/gerald_D1VCPACXX_5.bam";
  my $mv_cmd9 = "$op $bam_base/$data/gerald_C1TD1ACXX_7_CGATGT.bam $fs_base/csf_135416282/gerald_C1TD1ACXX_7_CGATGT.bam";
  my $mv_cmd10 = "$op $bam_base/$data/gerald_C1TD1ACXX_7_ATCACG.bam $fs_base/csf_135417932/gerald_C1TD1ACXX_7_ATCACG.bam";
  my $mv_cmd11 = "$op $bam_base/$data/gerald_C2DBEACXX_3.bam $fs_base/csf_142880229/gerald_C2DBEACXX_3.bam";
  my $mv_cmd12 = "$op $bam_base/$data/gerald_C1TD1ACXX_8_ACAGTG.bam $fs_base/csf_135450623/gerald_C1TD1ACXX_8_ACAGTG.bam";

  #Make sure the /opt/gms/GMS1 symlink is in place
  print "\n\nPlace BAM files into expected system paths within GMS1";
  my @op_cmds = ($mv_cmd1,$mv_cmd2,$mv_cmd3,$mv_cmd4,$mv_cmd5,$mv_cmd6,$mv_cmd7,$mv_cmd8,$mv_cmd9,$mv_cmd10,$mv_cmd11,$mv_cmd12);
  foreach my $op_cmd (@op_cmds){
    print "\nRUN: $op_cmd";
    system($op_cmd);
  }
}

#Perform some automatic sanity checks of the system and report problems to the user


print "\n\n";

exit;




