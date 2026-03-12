package DBIO::MSSQL::SQLMaker;
# ABSTRACT: MSSQL-specific SQL generation for DBIO

use warnings;
use strict;

use base qw( DBIO::SQLMaker );

=head1 DESCRIPTION

L<DBIO::SQLMaker> subclass for Microsoft SQL Server. Overrides the default
C<ROW_NUMBER() OVER()> order expression to use C<(SELECT(1))> because MSSQL
does not support an empty C<OVER()> clause.

Used automatically by L<DBIO::MSSQL::Storage>.

=cut

#
# MSSQL does not support ... OVER() ... RNO limits
#
sub _rno_default_order {
  return \ '(SELECT(1))';
}

=head1 SEE ALSO

=over

=item * L<DBIO::MSSQL::Storage> - MSSQL storage (uses this SQL maker)

=item * L<DBIO::SQLMaker> - Base SQL maker class

=back

=cut

1;
