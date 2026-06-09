package DBIO::MSSQL::Diff::Util;
# ABSTRACT: Comparison utilities for MSSQL diff operations

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
  is_same_column is_same_index is_same_fk _norm_type
);

=head1 DESCRIPTION

Centralized sameness checks for the MSSQL diff op classes
(L<DBIO::MSSQL::Diff::Column>, L<DBIO::MSSQL::Diff::Index>,
L<DBIO::MSSQL::Diff::ForeignKey>). Each C<is_same_*> returns the list of
field names that differ between an old and a new metadata hash; an empty
list means "no change". Counterpart to L<DBIO::MySQL::Diff::Util>.

Both sides are introspected native models (the test-deploy-and-compare
strategy introspects the live DB and the temp DB), so comparison works on
dialect type names. Column ordering is significant for composite indexes
and foreign keys, so column comparison is order-sensitive (unlike the
set-based MySQL helper).

=cut

=func _norm_type

Normalize a SQL type name for comparison: collapse internal whitespace and
upper-case. C<nvarchar(255)> and C<NVARCHAR(255)> compare equal.

=cut

sub _norm_type {
  my $t = shift // '';
  $t =~ s/\s+/ /g;
  return uc $t;
}

=func is_same_column

    my @changed = is_same_column($old, $new);

Compares data type, nullability, and default value.

=cut

sub is_same_column {
  my ($old, $new) = @_;
  my @changed;
  push @changed, 'data_type'
    if _norm_type($old->{data_type}) ne _norm_type($new->{data_type});
  push @changed, 'not_null'
    if ($old->{not_null} // 0) != ($new->{not_null} // 0);
  push @changed, 'default_value'
    if _norm_default($old->{default_value}) ne _norm_default($new->{default_value});
  return @changed;
}

=func is_same_index

    my @changed = is_same_index($old, $new);

Compares uniqueness and the (ordered) column list.

=cut

sub is_same_index {
  my ($old, $new) = @_;
  my @changed;
  push @changed, 'is_unique'
    if ($old->{is_unique} // 0) != ($new->{is_unique} // 0);
  push @changed, 'columns'
    if _cols_ne($old->{columns}, $new->{columns});
  return @changed;
}

=func is_same_fk

    my @changed = is_same_fk($old, $new);

Compares referenced table, the (ordered) local and remote column lists, and
the referential actions.

=cut

sub is_same_fk {
  my ($old, $new) = @_;
  my @changed;
  for my $field (qw(to_table on_delete on_update)) {
    push @changed, $field if _norm_default($old->{$field}) ne _norm_default($new->{$field});
  }
  push @changed, 'from_columns' if _cols_ne($old->{from_columns}, $new->{from_columns});
  push @changed, 'to_columns'   if _cols_ne($old->{to_columns},   $new->{to_columns});
  return @changed;
}

# Internal: undef-safe scalar normalize for comparison.
sub _norm_default {
  my ($v) = @_;
  return defined $v ? "$v" : '';
}

# Internal: order-sensitive column-list comparison. Returns true if differ.
sub _cols_ne {
  my ($a, $b) = @_;
  $a = ref($a) eq 'ARRAY' ? $a : [];
  $b = ref($b) eq 'ARRAY' ? $b : [];
  return join("\0", @$a) ne join("\0", @$b);
}

1;
