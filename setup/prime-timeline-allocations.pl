#!/usr/bin/env genome-perl
use strict;
use warnings;
use Genome;

my @event_types = qw ( created purged preserved moved reallocated archived strengthened weakened unarchived unpreserved finalized invalidated );

foreach my $event_type (@event_types){
  my $et = Genome::Timeline::Event::AllocationEventType->create(
    id => $event_type,
  );
}
UR::Context->commit();

__END__



