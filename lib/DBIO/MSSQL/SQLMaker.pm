package DBIO::MSSQL::SQLMaker;
# ABSTRACT: MSSQL-specific SQL generation for DBIO

use warnings;
use strict;

use base qw( DBIO::SQLMaker );

#
# MSSQL does not support ... OVER() ... RNO limits
#
sub _rno_default_order {
  return \ '(SELECT(1))';
}

1;
