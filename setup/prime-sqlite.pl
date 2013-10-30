#!/usr/bin/perl
use strict;
use warnings;
use Genome;
use Workflow;
Genome::DataSource::Meta->get_default_dbh();
Workflow::DataSource::Meta->get_default_dbh();
Workflow::DataSource::InstanceSchema->get_default_dbh();

