package DBIO::MSSQL::Diff;
# ABSTRACT: Compare two introspected MSSQL models
our $VERSION = '0.900000';

use strict;
use warnings;

use base 'DBIO::Diff::Base';

=head1 DESCRIPTION

C<DBIO::MSSQL::Diff> compares two introspected MSSQL models (produced
by L<DBIO::MSSQL::Introspect>) and emits a list of structured diff
operations that can be rendered to SQL or a human-readable summary.

    my $diff = DBIO::MSSQL::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Operations are emitted in dependency order: tables, then columns, then
indexes. Drops come last for each layer.

=cut

use DBIO::MSSQL::Diff::Table;
use DBIO::MSSQL::Diff::Column;
use DBIO::MSSQL::Diff::Index;

sub _build_operations {
  my ($self) = @_;
  my @ops;

  push @ops, DBIO::MSSQL::Diff::Table->diff(
    $self->source->{tables}, $self->target->{tables},
    $self->target->{columns}, $self->target->{foreign_keys},
  );
  push @ops, DBIO::MSSQL::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  push @ops, DBIO::MSSQL::Diff::Index->diff(
    $self->source->{indexes}, $self->target->{indexes},
  );

  return \@ops;
}

=seealso

=over

=item * L<DBIO::MSSQL::Introspect> - produces the models this class compares

=item * L<DBIO::MSSQL::Deploy> - uses this class for upgrade diffs

=back

=cut

1;
