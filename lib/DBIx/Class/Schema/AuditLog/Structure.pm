package DBIx::Class::Schema::AuditLog::Structure;

use base qw/DBIx::Class::Schema/;

use strict;
use warnings;

require DBIx::Class::Schema::AuditLog::Structure::Action;
require DBIx::Class::Schema::AuditLog::Structure::AuditedTable;
require DBIx::Class::Schema::AuditLog::Structure::Change;
require DBIx::Class::Schema::AuditLog::Structure::Changeset;
require DBIx::Class::Schema::AuditLog::Structure::Field;
require DBIx::Class::Schema::AuditLog::Structure::User;

__PACKAGE__->mk_group_accessors( simple => '_current_changeset_container' );

sub _current_changeset {
    my $self = shift;
    my $ref  = $self->_current_changeset_container;

    return $ref && $ref->{changeset};
}

=head2 current_changeset

Returns the changeset that is currently in process.

This is localized to the scope of each transaction.

=cut

sub current_changeset {
    my ( $self, @args ) = @_;

    $self->throw_exception('Cannot set changeset manually. Use txn_do.')
        if @args;

    # we only want to create a changeset if the action (insert/update/delete)
    # is being run from txn_do -- the txn_do method in
    # DBIx::Class::Schema::AuditLog sets local
    # _current_changeset_container->{changeset} &
    # _current_changeset_container->{args} variables in the scope
    # of each transaction
    if (   defined $self->_current_changeset_container
        && defined $self->_current_changeset_container->{changeset} )
    {

        my $id = $self->_current_changeset;

        unless ($id) {
            my $changeset = $self->audit_log_create_changeset(
                $self->_current_changeset_container->{args} );
            $self->_current_changeset_container->{changeset} = $changeset->id;
            $id = $changeset->id;
        }

        return $id;
    }

    return;
}

=head2 audit_log_create_changeset

Creates a new Changeset for audited Actions.

Will create a new Audit Log User if ncessary.

=cut

sub audit_log_create_changeset {
    my $self           = shift;
    my $changeset_data = shift;

    my ( $changeset, $user );

    if ( $changeset_data->{user_id} ) {
        $user = $self->resultset('AuditLogUser')
            ->find_or_create( { name => $changeset_data->{user_id} } );

        $changeset = $user->create_related( 'Changeset',
            { description => $changeset_data->{description} } );
    }
    else {
        $changeset = $self->resultset('AuditLogChangeset')
            ->create( { description => $changeset_data->{description} } );
    }

    return $changeset;
}

=head2 audit_log_create_action

Creates a related Action for the current Changeset.

Also will create an AuditedTable for the new action if
it doesn't already exist.

=cut

sub audit_log_create_action {
    my $self        = shift;
    my $action_data = shift;

    my $changeset = $self->current_changeset;

    if ($changeset) {
        my $table = $self->resultset('AuditLogAuditedTable')
            ->find_or_create( { name => $action_data->{table} } );

        return (
            $self->resultset('AuditLogChangeset')->find($changeset)
                ->create_related(
                'Action',
                {   audited_row      => $action_data->{row},
                    audited_table_id => $table->id,
                    action_type      => $action_data->{action_type},
                }
                ),
            $table
        );
    }

    return;
}

=head2 get_changes

Returns DBIC resultset of audit changes.

Takes a passed options hashref.

Required:
    id: row id from the table that was audited
    table:  name of the table that was audited
            this must include the schema name
            for databases that have multiple schemas

Optional:
    action_types: array ref of action types: [ delete, insert, update ]
    change_order: sets the order to return the results, either asc, or desc
                  defaults to desc
    field: name of the field that was audited
    created_on: timestamp of the changeset to search by
               takes a standard dbic where clause for a field,
               eg:
                   '2012-07-09-15.25.18'
                or
                   { '>=' , '2012-07-09-15.25.18; }
               the timestamp must already be in the format that the
               database stores in

=cut
sub get_changes {
    my $self    = shift;
    my $options = shift;

    my $audited_row  = $options->{id};
    my $change_order = $options->{change_order} || 'desc';
    my $field_name   = $options->{field};
    my $table_name   = $options->{table};
    my $timestamp    = $options->{created_on};
    my $action_types = $options->{action_types}
        || [ 'insert', 'update', 'delete' ];

    # row and table are required for all changes
    return if !$audited_row || !$table_name;

    my $table = $self->resultset('AuditLogAuditedTable')
        ->find( { name => $table_name, } );

    # cannot get changes if the specified table hasn't been logged
    return unless defined $table;

    my $changeset_criteria = {};
    $changeset_criteria->{created_on} = $timestamp if $timestamp;
    my $changesets = $self->resultset('AuditLogChangeset')
        ->search_rs( $changeset_criteria );

    my $actions = $changesets->search_related(
        'Action',
        {   audited_table_id => $table->id,
            audited_row      => $audited_row,
            action_type      => $action_types,
        }
    );

    if ( $actions && $actions->count ) {
        my $field = $table->find_related( 'Field', { name => $field_name } )
            if $field_name;

        # if field is passed and the passed field wasn't found in the Field
        # table set field id to -1 to ensure a $changes object with ->count =
        # 0 is returned
        my $criteria = {};
        if ( $field_name ) {
            $criteria->{field_id} = $field ? $field->id : -1;
        }

        my $changes = $actions->search_related( 'Change', $criteria,
            { order_by => { "-$change_order" => 'me.id' } } );
        return $changes;
    }

    return;
}

1;
