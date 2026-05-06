package DBIO::MSSQL::Introspect::Tables;
# ABSTRACT: Introspect MSSQL tables and views
our $VERSION = '0.900000';

use strict;
use warnings;

=head1 DESCRIPTION

Fetches MSSQL table and view metadata via C<INFORMATION_SCHEMA.TABLES>.
Skips system tables.

=cut

=method fetch

    my $tables = DBIO::MSSQL::Introspect::Tables->fetch($dbh, $schema);

Returns a hashref keyed by table name. Each value has: C<table_name>,
C<kind> (C<table> or C<view>), C<schema>.

=cut

sub fetch {
  my ($class, $dbh, $schema) = @_;
  $schema //= 'dbo';

  my $sth = $dbh->prepare(q{
    SELECT table_name, table_type
    FROM INFORMATION_SCHEMA.TABLES
    WHERE table_schema = ?
    ORDER BY table_name
  });
  $sth->execute($schema);

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    my $type = lc($row->{table_type} // '');
    my $kind = $type =~ /view/ ? 'view' : 'table';
    $tables{ $row->{table_name} } = {
      table_name => $row->{table_name},
      kind       => $kind,
      schema     => $schema,
    };
  }

  return \%tables;
}

1;
