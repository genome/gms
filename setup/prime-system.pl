#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long;

my $usage=<<INFO;

./prime-system.pl --data=hcc1395_1tenth_percent --sync=tarball 

Arguments:
--data            Data set to download ('hcc1395', 'hcc1395_1percent', 'hcc1395_1tenth_percent', 'hcc1395_exome_only', 'none')
--sync            Syncing method ('rsync', 'tarball')
--low_resources   Configure the system for a low resources test (e.g. if you have memory < 64Gb).  For demonstration purposes only  
--memory          Specify how many GB of memory you have available on your physical system or allocated in a VM. (e.g. --memory=8GB or --memory=8192MB)  
--help            Display this documentation

INFO

my $data = '';
my $sync = '';
my $low_resources;
my $memory = '';
my $help;

GetOptions ('data=s'=>\$data, 'sync=s'=>\$sync, 'low_resources'=>\$low_resources, 'memory=s'=>\$memory, 'help'=>\$help);

#Make sure the user is within the sGMS, install has been run and ENVs are set by checking for $GENOME_SYS_ID
unless ($ENV{GENOME_SYS_ID}){
  print "\n\nGENOME_SYS_ID is not set!  Are you logged in and the installation is complete?\n\n";
  exit();
}
if ($help || !$data || !$sync){
  print "$usage";
  exit();
}
unless ($data =~ /^hcc1395$|^hcc1395_1percent$|^hcc1395_1tenth_percent$|^hcc1395_exome_only$|^none$/){
  print "\n\nMust specify a valid value for --data: 'hcc1395', 'hcc1395_1percent', 'hcc1395_1tenth_percent', 'none'\n\n";
  exit();
}
unless ($sync =~ /^rsync$|^tarball$/){
  print "\n\nMust specify a valid value for --sync: 'tarball', 'rsync'\n\n";
  exit();
}

#Check resource config options
my $slots = 80;
my $memory_mb;
if ($memory || $low_resources){
  unless ($memory){
    print "\n\nIf --low_resources is specified, you must also specify the memory available in your system (e.g. --memory=8GB or --memory=8192MB)\n\n" unless ($memory);
    exit();
  }
  $low_resources = 1;
  chomp($memory);
  if ($memory =~ /^(\d+)gb$/i){
    $memory_mb = sprintf("%.0f", ($1 * 1000));
  }elsif($memory =~ /^(\d+)mb$/i){
    $memory_mb = $1;    
  }else{
    print "\n\nFormat of --memory not recognized. Specify available system memory in Gb (e.g. --memory=8GB or --memory=8192MB)\n\n";
    exit();
  }
  $memory_mb = sprintf("%.0f", ($memory_mb/$slots));
  print "\n\nWARNING: The system will be configured for low resource usage based on an available memory of $memory_mb MB";

  #Set MXJ value for 'default' host to a larger number (e.g., to 64) instead of '!' in /opt/openlava-2.2/etc/lsb.hosts.
  my $lsb_hosts_name = "lsb.hosts";
  my $lsb_hosts_path = "/opt/openlava-2.2/etc/";
  my $tmp_path = "/tmp/";
  open (LSBHOSTS1, "$lsb_hosts_path"."$lsb_hosts_name") || die "\n\nCan not open lsb hosts file: $lsb_hosts_path"."$lsb_hosts_name\n\n";
  open (LSBHOSTS2, ">$tmp_path"."$lsb_hosts_name") || die "\n\nCan not open temp lsb hosts file: $tmp_path"."$lsb_hosts_name\n\n";
  while(<LSBHOSTS1>){
    if ($_ =~ /^default\s+\!/){
      $_ =~ s/\!/80/;
      print LSBHOSTS2 $_;
    }else{
      print LSBHOSTS2 $_;
    }
  }
  close(LSBHOSTS1);
  close(LSBHOSTS2);
  my $mv_cmd = "sudo mv -f $tmp_path"."$lsb_hosts_name $lsb_hosts_path" . "$lsb_hosts_name";
  print "\n\nRUN: $mv_cmd";
  system($mv_cmd);
  my $restart_cmd = "sudo $lsb_hosts_path"."openlava restart";
  print "\n\nRUN: $restart_cmd";
  system($restart_cmd);

  #Set WF_LOW_MEMORY=$memory_mb in /etc/genome.conf
  #Set WF_LOW_RESOURCES=1 in /etc/genome.conf
  my $wf_low_resources_found = 0;
  my $wf_low_memory_found = 0;
  open (GENOME_CONF1, "/etc/genome.conf") || die "\n\nCan not open genome conf file: /etc/genome.conf\n\n";
  open (GENOME_CONF2, ">/tmp/genome.conf") || die "\n\nCan not open temp genome conf file: /tmp/genome.conf\n\n"; 
  while(<GENOME_CONF1>){
    if ($_ =~ /export\s+WF\_LOW\_RESOURCES\=0/){
      print GENOME_CONF2 "export WF_LOW_RESOURCES=1\n";
      $wf_low_resources_found = 1;
    }elsif ($_ =~ /export\s+WF\_LOW\_MEMORY=\d+/){
      print GENOME_CONF2 $_;
      $wf_low_memory_found = 1;
    }else{
      print GENOME_CONF2 $_;
    }
  }
  print GENOME_CONF2 "export WF_LOW_RESOURCES=1\n" unless ($wf_low_resources_found);
  print GENOME_CONF2 "export WF_LOW_MEMORY="."$memory_mb\n" unless ($wf_low_memory_found);
  close(GENOME_CONF1);
  close(GENOME_CONF2);
 
  $mv_cmd = "sudo mv -f /tmp/genome.conf /etc/genome.conf";
  print "\n\nRUN: $mv_cmd";
  system($mv_cmd);
  my $source_cmd = "bash /etc/genome.conf";
  print "\n\nRUN: $source_cmd\n";
  system($source_cmd);
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
  #all data
  my $bam_list = "gerald_D1VCPACXX_6.bam gerald_D1VCPACXX_7.bam gerald_D1VCPACXX_8.bam gerald_D1VCPACXX_1.bam gerald_D1VCPACXX_2.bam gerald_D1VCPACXX_3.bam gerald_D1VCPACXX_4.bam gerald_D1VCPACXX_5.bam gerald_C1TD1ACXX_7_CGATGT.bam gerald_C1TD1ACXX_7_ATCACG.bam gerald_C2DBEACXX_3.bam gerald_C1TD1ACXX_8_ACAGTG.bam";
  if ($data eq "hcc1395_exome_only"){
    $bam_list = "gerald_C1TD1ACXX_7_CGATGT.bam gerald_C1TD1ACXX_7_ATCACG.bam";
  }

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
  my @op_cmds = ($mv_cmd1,$mv_cmd2,$mv_cmd3,$mv_cmd4,$mv_cmd5,$mv_cmd6,$mv_cmd7,$mv_cmd8,$mv_cmd9,$mv_cmd10,$mv_cmd11,$mv_cmd12);
  if ($data eq "hcc1395_exome_only"){
    @op_cmds = ($mv_cmd9,$mv_cmd10); 
  }

  #Make sure the /opt/gms/GMS1 symlink is in place
  print "\n\nPlace BAM files into expected system paths within GMS1";
  foreach my $op_cmd (@op_cmds){
    print "\nRUN: $op_cmd";
    system($op_cmd);
  }
}

#Perform some automatic sanity checks of the system and report problems to the user


#If this config has modified /etc/genome.conf 
print "\n\nYour config file (/etc/genome.conf) may have been modified, to be safe you should logout and login again" if ($memory || $low_resources);

print "\n\n";

exit;

