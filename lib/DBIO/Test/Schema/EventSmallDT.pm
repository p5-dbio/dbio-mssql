package DBIO::Test::Schema::EventSmallDT;
# ABSTRACT: Test result class for the event_small_dt table (smalldatetime)
use strict;
use warnings;
use base 'DBIO::Test::BaseResult';

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table('event_small_dt');
__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },
  small_dt => { data_type => 'smalldatetime', is_nullable => 1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->resultset_class('DBIO::Test::BaseResultSet');
1;
