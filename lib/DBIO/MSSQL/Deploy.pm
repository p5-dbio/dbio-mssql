package DBIO::MSSQL::Deploy;
# ABSTRACT: Deploy and upgrade MSSQL schemas via test-deploy-and-compare

use strict;
use warnings;

use DBI;
use DBIO::SQL::Util qw(_split_statements);
use DBIO::MSSQL::DDL;
use DBIO::MSSQL::Introspect;
use DBIO::MSSQL::Diff;

=head1 DESCRIPTION

C<DBIO::MSSQL::Deploy> orchestrates schema deployment and upgrades for
Microsoft SQL Server using the test-deploy-and-compare strategy.

For upgrades it:

=over 4

=item 1. Introspects the live database via C<INFORMATION_SCHEMA>

=item 2. Deploys the desired schema (from DBIO classes) into a temp DB

=item 3. Introspects the temp database the same way

=item 4. Computes the diff between the two models using L<DBIO::MSSQL::Diff>

=back

    my $deploy = DBIO::MSSQL::Deploy->new(
        schema => MyApp::DB->connect($dsn),
    );
    $deploy->install;                       # fresh
    my $diff = $deploy->diff;               # or step-by-step
    $deploy->apply($diff) if $diff->has_changes;
    $deploy->upgrade;                       # convenience

=cut

sub new {
  my ($class, %args) = @_;
  bless \%args, $class;
}

sub schema { $_[0]->{schema} }

=attr schema

A connected L<DBIO::Schema> instance using the L<DBIO::MSSQL> component.
Required.

=cut

=method install

    $deploy->install;

Generates DDL via L<DBIO::MSSQL::DDL/install_ddl> and executes each
statement against the connected database. Suitable for fresh installs.

=cut

sub install {
  my ($self) = @_;
  my $ddl = DBIO::MSSQL::DDL->install_ddl($self->schema);
  my $dbh = $self->_dbh;
  for my $stmt (_split_statements($ddl)) {
    $dbh->do($stmt);
  }
  return 1;
}

=method diff

    my $diff = $deploy->diff;

Computes the difference between the live database and the desired state.
Spins up a temporary MSSQL database, deploys the desired schema there,
introspects both, and returns a L<DBIO::MSSQL::Diff> object.

=cut

sub diff {
  my ($self) = @_;

  my $source_model = DBIO::MSSQL::Introspect->new(dbh => $self->_dbh)->model;

  my $temp_db = $self->_create_temp_db;
  my $temp_dbh = $self->_connect_to_temp_db($temp_db);

  eval {
    my $ddl = DBIO::MSSQL::DDL->install_ddl($self->schema);
    for my $stmt (_split_statements($ddl)) {
      $temp_dbh->do($stmt);
    }
  };
  my $deploy_err = $@;

  my $target_model;
  unless ($deploy_err) {
    eval {
      $target_model = DBIO::MSSQL::Introspect->new(dbh => $temp_dbh)->model;
    };
    $deploy_err = $@ unless $target_model;
  }

  $temp_dbh->disconnect;
  $self->_drop_temp_db($temp_db);

  die $deploy_err if $deploy_err;

  return DBIO::MSSQL::Diff->new(
    source => $source_model,
    target => $target_model,
  );
}

=method apply

    $deploy->apply($diff);

Applies a L<DBIO::MSSQL::Diff> object by executing each statement from
C<< $diff->as_sql >>. No-op if the diff has no changes.

=cut

sub apply {
  my ($self, $diff) = @_;
  return unless $diff->has_changes;
  my $dbh = $self->_dbh;
  for my $stmt (_split_statements($diff->as_sql)) {
    next if $stmt =~ /^\s*--/;
    $dbh->do($stmt);
  }
  return 1;
}

=method upgrade

    my $diff = $deploy->upgrade;

Convenience: calls L</diff> then L</apply>. Returns the diff object if
changes were applied, or C<undef> if the database was already up to date.

=cut

sub upgrade {
  my ($self) = @_;
  my $diff = $self->diff;
  return unless $diff->has_changes;
  $self->apply($diff);
  return $diff;
}

sub _dbh { $_[0]->schema->storage->dbh }

sub _create_temp_db {
  my ($self) = @_;
  my $name = '_dbio_tmp_' . $$ . '_' . time();
  my $dbh = $self->_dbh;
  $dbh->do("COMMIT") if $dbh->{AutoCommit} == 0;
  local $dbh->{AutoCommit} = 1;
  $dbh->do("CREATE DATABASE $name");
  return $name;
}

sub _drop_temp_db {
  my ($self, $name) = @_;
  my $dbh = $self->_dbh;
  local $dbh->{AutoCommit} = 1;
  $dbh->do("DROP DATABASE $name");
}

sub _connect_to_temp_db {
  my ($self, $temp_db) = @_;
  my ($dsn, $user, $pass) = $self->_temp_connect_info($temp_db);
  return DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, AutoCommit => 1,
  }) or die "Cannot connect to temp database: $DBI::errstr";
}

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
    die "DBIO::MSSQL::Deploy does not support coderef DSN for temp database connections";
  }

  # Replace database name in DSN
  if ($dsn =~ /Database=/i || $dsn =~ /dbname=/i) {
    $dsn =~ s/(Database|dbname)=[^;]*/Database=$temp_db/i;
  } else {
    $dsn .= ";Database=$temp_db";
  }

  return ($dsn, $user, $pass);
}

=seealso

=over

=item * L<DBIO::MSSQL> - schema component

=item * L<DBIO::MSSQL::DDL> - generates DDL

=item * L<DBIO::MSSQL::Introspect> - reads live database state

=item * L<DBIO::MSSQL::Diff> - compares two introspected models

=back

=cut

1;
