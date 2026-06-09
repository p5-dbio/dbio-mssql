package DBIO::MSSQL::Deploy;
# ABSTRACT: Deploy and upgrade MSSQL schemas via test-deploy-and-compare

use strict;
use warnings;

use base 'DBIO::Deploy::Base::TempDatabase';

use DBIO::MSSQL::DDL;
use DBIO::MSSQL::Introspect;
use DBIO::MSSQL::Diff;

=head1 DESCRIPTION

C<DBIO::MSSQL::Deploy> orchestrates schema deployment and upgrades for
Microsoft SQL Server using the test-deploy-and-compare strategy.

The orchestration (C<install>, C<diff>, C<apply>, C<upgrade>) and the
temp-database lifecycle are inherited from
L<DBIO::Deploy::Base::TempDatabase>: C<diff> introspects the live database,
deploys the desired DDL into a throwaway database, introspects that, and
diffs the two models. This class supplies only the MSSQL-specific seams: the
three class-name hooks and the C<CREATE>/C<DROP DATABASE> dialect.

    my $deploy = DBIO::MSSQL::Deploy->new(
        schema => MyApp::DB->connect($dsn),
    );
    $deploy->install;                       # fresh
    my $diff = $deploy->diff;               # or step-by-step
    $deploy->apply($diff) if $diff->has_changes;
    $deploy->upgrade;                       # convenience

=cut

sub _ddl_class        { 'DBIO::MSSQL::DDL' }
sub _introspect_class { 'DBIO::MSSQL::Introspect' }
sub _diff_class       { 'DBIO::MSSQL::Diff' }

=method _create_temp_db

    my $name = $self->_create_temp_db($dbh);

Creates a uniquely-named throwaway database with T-SQL C<CREATE DATABASE>.
MSSQL cannot run C<CREATE DATABASE> inside a transaction, so any open
transaction is committed and the statement runs with autocommit on.

=cut

sub _create_temp_db {
  my ($self, $dbh) = @_;
  my $name = $self->temp_db_prefix . $$ . '_' . time();
  $dbh->do("COMMIT") if defined $dbh->{AutoCommit} && $dbh->{AutoCommit} == 0;
  local $dbh->{AutoCommit} = 1;
  $dbh->do("CREATE DATABASE $name");
  return $name;
}

=method _drop_temp_db

    $self->_drop_temp_db($dbh, $name);

Drops the throwaway database with T-SQL C<DROP DATABASE>.

=cut

sub _drop_temp_db {
  my ($self, $dbh, $name) = @_;
  local $dbh->{AutoCommit} = 1;
  $dbh->do("DROP DATABASE $name");
}

=method _temp_connect_info

Overrides the base derivation: MSSQL DSNs use the C<Database=> attribute, so
both the rewrite and the append-when-absent case emit C<Database=> (the base
default appends C<dbname=>, which an ODBC/Sybase MSSQL DSN does not honour).

=cut

sub _temp_connect_info {
  my ($self, $temp_db) = @_;
  my $storage = $self->schema->storage;
  my @connect_info = @{ $storage->connect_info };

  my ($dsn, $user, $pass);
  if (ref $connect_info[0] eq 'HASH') {
    my $h = $connect_info[0];
    $dsn  = $h->{dsn};
    $user = $h->{user};
    $pass = $h->{password} // $h->{pass};
  } else {
    ($dsn, $user, $pass) = @connect_info;
  }

  if (ref $dsn eq 'CODE') {
    die ref($self) . ' does not support coderef DSN for temp database connections';
  }

  if ($dsn =~ /(?:Database|dbname)=/i) {
    $dsn =~ s/(?:Database|dbname)=[^;]*/Database=$temp_db/i;
  } else {
    $dsn .= ";Database=$temp_db";
  }

  return ($dsn, $user, $pass);
}

=seealso

=over

=item * L<DBIO::Deploy::Base::TempDatabase> - shared temp-database orchestration

=item * L<DBIO::MSSQL> - schema component

=item * L<DBIO::MSSQL::DDL> - generates DDL

=item * L<DBIO::MSSQL::Introspect> - reads live database state

=item * L<DBIO::MSSQL::Diff> - compares two introspected models

=back

=cut

1;
