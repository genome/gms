#!/usr/bin/perl

use warnings;
use strict;
use Genome;
use Getopt::Long;

my $usage=<<INFO;
Example Usage:
./prime-system.pl --data=hcc1395_1tenth_percent --sync=tarball --metadata=gms/setup/metadata/18177dd5eca44514a47f367d9804e17a.dat

Arguments:
--data            Data set to download ('hcc1395', 'hcc1395_1percent', 'hcc1395_1tenth_percent', 'hcc1395_exome_only', 'none')
--metadata        Metadata file to be imported
--sync            Syncing method ('rsync', 'tarball')
--low_resources   Configure the system for a low resources test (e.g., if you have memory < 64Gb).  For demonstration purposes only  
--memory          Specify how many GB of memory you have available on your physical system or allocated in a VM. (e.g., --memory=8GB or --memory=8192MB)  
--cpus            Specify how many cpus you have available on your physical system or allocated in a VM (e.g., --cpus=8)
--username        Username to add to the users table. [pwuid]
--name            Name of the user to add to the users table. [username]
--email           Email of the user to add to the users table. [username\@temp.com]
--help            Display this documentation

INFO

my $data = '';
my $metadata = '';
my $sync = '';
my $low_resources;
my $memory = '';
my $cpus;
my $help;

GetOptions (
  'data=s'=>\$data,
  'metadata=s'=>\$metadata,
  'sync=s'=>\$sync,
  'low_resources'=>\$low_resources,
  'memory=s'=>\$memory,
  'cpus=s'=>\$cpus,
  'help'=>\$help
);

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
  print $usage;
  print "\n\nMust specify a valid value for --data: 'hcc1395', 'hcc1395_1percent', 'hcc1395_1tenth_percent', 'none'\n\n";
  exit();
}
unless ($sync =~ /^rsync$|^tarball$/){
  print $usage;
  print "\n\nMust specify a valid value for --sync: 'tarball', 'rsync'\n\n";
  exit();
}
unless (-e $metadata){
  print $usage;
  die print STDERR "Unable to find metadata file $metadata";
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

  #Set MXJ value for 'default' host to a larger number (e.g., to 80) instead of '!' in /opt/openlava-2.2/etc/lsb.hosts.
  #For larger numbers of cpus increased jobs slots are possible, otherwise default to 80
  if ($cpus){
    if ($cpus>8){
      $slots = $cpus * 10;
    }
  }
  my $lsb_hosts_name = "lsb.hosts";
  my $lsb_hosts_path = "/opt/openlava-2.2/etc/";
  my $tmp_path = "/tmp/";
  open (LSBHOSTS1, "$lsb_hosts_path"."$lsb_hosts_name") || die "\n\nCan not open lsb hosts file: $lsb_hosts_path"."$lsb_hosts_name\n\n";
  open (LSBHOSTS2, ">$tmp_path"."$lsb_hosts_name") || die "\n\nCan not open temp lsb hosts file: $tmp_path"."$lsb_hosts_name\n\n";
  while(<LSBHOSTS1>){
    if ($_ =~ /^default\s+\!/){
      $_ =~ s/\!/$slots/;
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

#Import the meta-data using 'genome model import metadata'
#File based databases from github will also be installed during this step
my $import_cmd = "genome model import metadata $metadata";
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
    my $got_tarball = 1;
    while ($got_tarball){
      $got_tarball = &get_tarball('-tarname'=>$tarname);
    }
    
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

#create necessary users for the SGMS. defaults to genome and current user.
create_admin_role();
my ($name, $username, $email) = get_user_info();
add_user($name, $email, $username);
add_user("Genome", "genome\@temp.com", "genome");
assign_role_user("admin", "genome\@temp.com");

#If this config has modified /etc/genome.conf 
print "\n\nYour config file (/etc/genome.conf) may have been modified, to be safe you should logout and login again" if ($memory || $low_resources);

print "\n\n";

exit;

#get info for current user
sub get_user_info {
  my ($name, $username, $email);
  GetOptions (
    'name=s'=>\$name,
    'username=s'=>\$username,
    'email=s'=>\$email,
    'help'=>\&usage
  );
  $username //= getpwuid($<);
  $name //= $username;
  $email //= $username . "\@temp.com";
  printf "\nFound user: %s\t%s\t%s", $name, $username, $email;
  return ($name, $username, $email);
}

#create a role called admin
sub create_admin_role {
  print "\nCreating role admin";
  my $dbh = Genome::Sys::User::Role->__meta__->data_source->get_default_handle;
  my $sth = $dbh->prepare('INSERT INTO subject.role (id, name) VALUES (?,?)');
  $sth->execute("4AAB87D4743D11E1AD77BD4F3B8842A7", "admin");
}

#add a new user
sub add_user {
  my $name = shift;
  my $email = shift;
  my $username = shift;
  print "\nAdding user $username";
  my $dbh = Genome::Sys::User->__meta__->data_source->get_default_handle;
  my $sth = $dbh->prepare('INSERT INTO subject.user (name, email, username) VALUES (?,?,?)');
  $sth->execute($name, $email, $username);
}

#assign role to user
sub assign_role_user {
  my $role = shift;
  my $email = shift;
  print "\nMaking user $email into role $role";
  my $role_id = Genome::Sys::User::Role->get(name => $role)->id;
  my $dbh = Genome::Sys::User::RoleMember->__meta__->data_source->get_default_handle;
  my $sth = $dbh->prepare('INSERT INTO subject.role_member (user_email, role_id) VALUES (?,?)');
  $sth->execute($email, $role_id);
}

sub get_tarball{
  my %args = @_;
  my $tarname = $args{'-tarname'};

  #If there is already a tarball present, delete it
  my $rm_cmd = "rm -fr /opt/gms/$tarname";

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
  my $error_code = $?;

  if ($error_code){
    print "\n\nWarning failed to download tarball!";
  }

  return $error_code;
}

