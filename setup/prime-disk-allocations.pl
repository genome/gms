#!/usr/bin/env genome-perl
use strict;
use warnings;
use Genome;

my $genome_sys_id = $ENV{GENOME_SYS_ID};
my $genome_node_id = $ENV{GENOME_SYS_ID};

my $path = "/opt/gms/$genome_sys_id/fs/$genome_node_id";
my $total_kb = 100;
unless (-e $path) {
    Genome::Sys->create_directory($path);
}

my $v = Genome::Disk::Volume->create(
  total_kb => $total_kb,
  can_allocate => 1,
  disk_status => 'active',
  physical_path => $path,
  mount_path => $path,
  hostname => $genome_sys_id,
);
$v->sync_total_kb;
print $v->mount_path,"\t",$v->is_mounted,"\t",$v->total_kb,"\n";

my @g = (
  subdirectory=> 'info',
  unix_gid => 2001,
  unix_uid => 2001,
  #sticky => 1,
  permissions => '775',
);

my $g1 = Genome::Disk::Group->create(
  id => 168, 
  disk_group_name => 'info_alignments',
  @g
);

my $g2 = Genome::Disk::Group->create(
  id => 169,
  disk_group_name => 'info_genome_models',
  @g
);

my $g3 = Genome::Disk::Group->create(
  id => 172,
  disk_group_name => 'info_apipe_ref',
  @g
);

my $g4 = Genome::Disk::Group->create(
  id => '1',
  disk_group_name => 'reads',
  @g
);

for my $g ($g1, $g2, $g3, $g4) {
  my $a = Genome::Disk::Assignment->create(
    dv_id => $v->id,
    dg_id => $g->id,
  );
}

UR::Context->commit();

__END__
# Genome::Disk::Assignment
bless( {"db_committed" => {"dv_id" => 14406,"dg_id" => 168},"dv_id" => 14406,"id" => "168\t14406","dg_id" => 168}, 'Genome::Disk::Assignment' )
bless( {"db_committed" => {"dv_id" => 9981,"dg_id" => 168},"dv_id" => 9981,"id" => "168\t9981","dg_id" => 168}, 'Genome::Disk::Assignment' )
bless( {"db_committed" => {"dv_id" => 14315,"dg_id" => 169},"dv_id" => 14315,"id" => "169\t14315","dg_id" => 169}, 'Genome::Disk::Assignment' )
bless( {"db_committed" => {"dv_id" => 14365,"dg_id" => 169},"dv_id" => 14365,"id" => "169\t14365","dg_id" => 169}, 'Genome::Disk::Assignment' )
bless( {"db_committed" => {"dv_id" => 1403,"dg_id" => 172},"dv_id" => 1403,"id" => "172\t1403","dg_id" => 172}, 'Genome::Disk::Assignment' )
## Genome::Disk::Volume

bless( {"db_committed" => {"total_kb" => "0","hostname" => "gpfs","_placeholder_creation_event_id" => 1,"can_allocate" => 1,"cached_unallocated_kb" => ,"disk_status" => "active","mount_path" => "/opt/gms/fs/ams1102","dv_id" => 1403,"physical_path" => "/vol/ams1102"},"total_kb" => "3221225472","_placeholder_creation_event_id" => 104048931,"hostname" => "gpfs","can_allocate" => 0,"cached_unallocated_kb" => 171199168,"disk_status" => "active","mount_path" => "/opt/gms/fs/ams1102","dv_id" => 1403,"id" => 1403,"physical_path" => "/vol/ams1102"}, 'Genome::Disk::Volume' )
bless( {"db_committed" => {"total_kb" => "214748364800","hostname" => "gpfs225","_placeholder_creation_event_id" => 1,"can_allocate" => 0,"cached_unallocated_kb" => "-2986643873","disk_status" => "active","mount_path" => "/opt/gms/fs/gc12001","dv_id" => 14315,"physical_path" => "/vol/aggr11/gc12001"},"total_kb" => "214748364800","_placeholder_creation_event_id" => 122766090,"hostname" => "gpfs225","can_allocate" => 0,"cached_unallocated_kb" => "-2986643873","disk_status" => "active","mount_path" => "/opt/gms/fs/gc12001","dv_id" => 14315,"id" => 14315,"physical_path" => "/vol/aggr11/gc12001"}, 'Genome::Disk::Volume' )
bless( {"db_committed" => {"total_kb" => "53687091200","hostname" => "gpfs224","_placeholder_creation_event_id" => 1,"can_allocate" => 0,"cached_unallocated_kb" => "10819066808","disk_status" => "active","mount_path" => "/opt/gms/fs/gc12002","dv_id" => 14365,"physical_path" => "/vol/aggr11/gc12002"},"total_kb" => "53687091200","_placeholder_creation_event_id" => 127329677,"hostname" => "gpfs224","can_allocate" => 0,"cached_unallocated_kb" => "10819066808","disk_status" => "active","mount_path" => "/opt/gms/fs/gc12002","dv_id" => 14365,"id" => 14365,"physical_path" => "/vol/aggr11/gc12002"}, 'Genome::Disk::Volume' )
bless( {"db_committed" => {"total_kb" => "293131517952","hostname" => "gpfs224","_placeholder_creation_event_id" => 129756456,"can_allocate" => 1,"cached_unallocated_kb" => "59712417360","disk_status" => "active","mount_path" => "/opt/gms/fs/gc13000","dv_id" => 14406,"physical_path" => "/vol/aggr13/gc13000"},"total_kb" => "293131517952","_placeholder_creation_event_id" => 129756456,"hostname" => "gpfs224","can_allocate" => 1,"cached_unallocated_kb" => "59712417360","disk_status" => "active","mount_path" => "/opt/gms/fs/gc13000","dv_id" => 14406,"id" => 14406,"physical_path" => "/vol/aggr13/gc13000"}, 'Genome::Disk::Volume' )
bless( {"db_committed" => {"total_kb" => "12884901888","hostname" => "gpfs","_placeholder_creation_event_id" => 110334322,"can_allocate" => 0,"cached_unallocated_kb" => "3598728171","disk_status" => "active","mount_path" => "/opt/gms/fs/ams1178","dv_id" => 9981,"physical_path" => "/vol/ams1178"},"total_kb" => "12884901888","_placeholder_creation_event_id" => 110334322,"hostname" => "gpfs","can_allocate" => 0,"cached_unallocated_kb" => "3598728171","disk_status" => "active","mount_path" => "/opt/gms/fs/ams1178","dv_id" => 9981,"id" => 9981,"physical_path" => "/vol/ams1178"}, 'Genome::Disk::Volume' )
