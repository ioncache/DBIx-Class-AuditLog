package DBIx::Class::AuditLog;

use base qw/DBIx::Class/;

use strict;
use warnings;

our $VERSION = '0.010000';

=head1 DBIx::Class OVERRIDDEN METHODS

=head2 insert

=cut

sub insert {
    my $self = shift;

    return $self->next::method(@_) if $self->in_storage;

    my $result = $self->next::method(@_);

    my ( $action, $table ) = $self->_action_setup( $result, 'insert' );

    if ($action) {
        my %column_data = $result->get_columns;
        $self->_store_changes( $action, $table, {}, \%column_data );
    }

    return $result;
}

=head2 update

=cut

sub update {
    my $self = shift;

    my $stored_row = $self->get_from_storage;
    my %old_data   = $stored_row->get_columns;
    my %new_data   = $self->get_dirty_columns;

    my $result = $self->next::method(@_);

    # find list of passed in update values when $row->update({...}) is used
    if ( my $updated_column_set = $_[0] ) {
        @new_data{ keys %$updated_column_set } = values %$updated_column_set;
    }

    foreach my $key ( keys %new_data ) {
        if (   defined $old_data{$key}
            && defined $new_data{$key}
            && $old_data{$key} eq $new_data{$key} )
        {
            delete $new_data{$key};
        }
    }

    if ( keys %new_data ) {
        my ( $action, $table )
            = $self->_action_setup( $stored_row, 'update' );

        if ($action) {
            $self->_store_changes( $action, $table, \%old_data, \%new_data );
        }
    }

    return $result;
}

=head2 delete

=cut

sub delete {
    my $self = shift;

    my $stored_row = $self->get_from_storage;

    my $result = $self->next::method(@_);

    my ( $action, $table ) = $self->_action_setup( $stored_row, 'delete' );

    if ($action) {
        my %old_data = $stored_row->get_columns;
        $self->_store_changes( $action, $table, \%old_data, {} );
    }

    return $result;
}

=head1 HELPER METHODS

=head2 _audit_log_schema

Returns the AuditLog schema from storage.

    my $al_schema = $schmea->audit_log_schema;

=cut

sub _audit_log_schema {
    my $self = shift;
    return $self->result_source->schema->audit_log_schema;
}

=head2 _action_setup

Creates a new AuditLog Action for a specific type.

Requires:
    row: primary key of the table that is being audited
    type: action type, 1 of insert/update/delete

=cut

sub _action_setup {
    my $self = shift;
    my $row  = shift;
    my $type = shift;

    return $self->_audit_log_schema->audit_log_create_action(
        {   row   => $row->id,
            table => $row->result_source_instance->name,
            type  => $type,
        }
    );

}

=head2 _store_changes

Store the column data that has changed

Requires:
    action: the action object that has associated changes
    old_values: the old values are being replaced
    new_values: the new values that are replacing the old
    table: dbic object of the audit_log_table object
=cut

sub _store_changes {
    my $self       = shift;
    my $action     = shift;
    my $table      = shift;
    my $old_values = shift;
    my $new_values = shift;

    foreach my $column (
        keys %{$new_values} ? keys %{$new_values} : keys %{$old_values} )
    {
        if ( $self->_do_audit($column) ) {
            my $field
                = $table->find_or_create_related( 'Field', { name => $column } );

            $action->create_related(
                'Change',
                {   field     => $field->id,
                    new_value => $new_values->{$column},
                    old_value => $old_values->{$column},
                }
            );
        }
    }
}

=head2 _do_audit

Returns 1 or 0 if the column should be audited or not.

Requires:
    column: the name of the column/field to check

=cut

sub _do_audit {
    my $self = shift;
    my $column = shift;

    my $info = $self->column_info($column);
    return defined $info->{audit_log_column} && $info->{audit_log_column} == 0 ? 0 : 1;
}

# ABSTRACT: Simple activity audit logging for DBIx::Class

1;
