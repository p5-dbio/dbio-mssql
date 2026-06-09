package DBIO::MSSQL::SQLMaker;
# ABSTRACT: MSSQL-specific SQL generation for DBIO

use warnings;
use strict;

use base qw( DBIO::SQLMaker );

=head1 DESCRIPTION

L<DBIO::SQLMaker> subclass for Microsoft SQL Server. Implements LIMIT/OFFSET
via C<ROW_NUMBER() OVER()> (the dialect SQL Server 2005+ supports) and
overrides the default C<OVER()> order expression to use C<(SELECT(1))>
because MSSQL does not support an empty C<OVER()> clause.

Used automatically by L<DBIO::MSSQL::Storage>.

=cut

=method apply_limit

    my $sql = $sqlmaker->apply_limit($sql, $rs_attrs, $rows, $offset);

MSSQL has no C<LIMIT>/C<OFFSET> keyword (before 2012's C<OFFSET ... FETCH>).
DBIO targets the broadly compatible C<ROW_NUMBER() OVER()> windowing
dialect: the query is wrapped in a derived table that numbers rows, then
sliced by C<WHERE rno BETWEEN offset+1 AND offset+rows>. Replaces the
DBIx::Class C<sql_limit_dialect> string dispatch.

=cut

sub apply_limit {
  my ($self, $sql, $rs_attrs, $rows, $offset) = @_;
  return $self->_RowNumberOver($sql, $rs_attrs, $rows, $offset);
}

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
