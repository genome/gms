#!/usr/bin/perl

use warnings;
use strict;

#Location of target full size BAMs to be replaced
my $base_dir = "/opt/gms/GMS1/fs/";
unless (-e $base_dir && -d $base_dir){
  die print "\nCould not find expected base dir: $base_dir\nStill need to sync GMS1 data?";
}

my %files;
$files{'gerald_C1TD1ACXX_7_ATCACG.bam'}{replacement_path} = $base_dir . "gc6001/production/csf_135417932/gerald_C1TD1ACXX_7_ATCACG.bam";
$files{'gerald_C1TD1ACXX_7_CGATGT.bam'}{replacement_path} = $base_dir . "gc6001/production/csf_135416282/gerald_C1TD1ACXX_7_CGATGT.bam";
$files{'gerald_D1VCPACXX_1.bam'}{replacement_path} = $base_dir . "gc6001/production/csf_135293260/gerald_D1VCPACXX_1.bam";
$files{'gerald_D1VCPACXX_2.bam'}{replacement_path} = $base_dir . "gc6001/production/csf_135290829/gerald_D1VCPACXX_2.bam";
$files{'gerald_D1VCPACXX_3.bam'}{replacement_path} = $base_dir . "gc6001/production/csf_135290878/gerald_D1VCPACXX_3.bam";
$files{'gerald_D1VCPACXX_4.bam'}{replacement_path} = $base_dir . "gc6001/production/csf_135291736/gerald_D1VCPACXX_4.bam";
$files{'gerald_D1VCPACXX_5.bam'}{replacement_path} = $base_dir . "gc6001/production/csf_135294298/gerald_D1VCPACXX_5.bam";
$files{'gerald_D1VCPACXX_6.bam'}{replacement_path} = $base_dir . "gc6001/production/csf_135291690/gerald_D1VCPACXX_6.bam";
$files{'gerald_D1VCPACXX_7.bam'}{replacement_path} = $base_dir . "gc6001/production/csf_135292156/gerald_D1VCPACXX_7.bam";
$files{'gerald_D1VCPACXX_8.bam'}{replacement_path} = $base_dir . "gc6001/production/csf_135291998/gerald_D1VCPACXX_8.bam";
$files{'gerald_C1TD1ACXX_8_ACAGTG.bam'}{replacement_path} = $base_dir . "gc6001/production/csf_135450623/gerald_C1TD1ACXX_8_ACAGTG.bam";
$files{'gerald_C2DBEACXX_3.bam'}{replacement_path} = $base_dir . "gc6001/production/csf_142880229/gerald_C2DBEACXX_3.bam";


foreach my $file (sort keys %files){
  print "\n\nProcessing: $file";
  my $replacement_path = $files{$file}{replacement_path};
  my $backup_file = $replacement_path . ".full";
  if (-e $backup_file){
    my $mv_cmd = "mv $backup_file $replacement_path";
    print "\n$mv_cmd";
    system($mv_cmd);
  }else{
    print "\nCould not find backup file for $replacement_path\n";
  }
}

print "\n\n";
exit;

