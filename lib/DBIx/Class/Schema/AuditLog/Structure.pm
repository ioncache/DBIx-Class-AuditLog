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

    if ( $changeset_data->{user} ) {
        $user = $self->resultset('AuditLogUser')
            ->find_or_create( { name => $changeset_data->{user} } );

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
                {   audited_row   => $action_data->{row},
                    audited_table => $table->id,
                    type          => $action_data->{type},
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
    field: name of the field that was audited
    action_types: array ref of action types: [ delete, insert, update ]

=cut
sub get_changes {
    my $self    = shift;
    my $options = shift;

    my $audited_row  = $options->{id};
    my $table_name   = $options->{table};
    my $field_name   = $options->{field};
    my $timestamp    = $options->{timestamp};
    my $action_types = $options->{action_types}
        || [ 'insert', 'update', 'delete' ];

    return if !$audited_row || !$table_name;

    my $schema = $self;

    my $table = $schema->resultset('AuditLogAuditedTable')
        ->find( { name => $table_name, } );

    my %changeset_criteria;
    $changeset_criteria{timestamp} = $timestamp if $timestamp;
    my $changesets = $schema->resultset('AuditLogChangeset')
        ->search( \%changeset_criteria );

    my $actions = $changesets->search_related(
        'Action',
        {   audited_table => $table->id,
            audited_row   => $audited_row,
            type          => $action_types,
        }
    ) if $table;

    if ( $actions && $actions->count ) {
        my $field = $table->find_related( 'Field', { name => $field_name } )
            if $field_name;

        my $criteria = {};
        $criteria->{field} = $field->id if $field;

        my $changes = $actions->search_related( 'Change', $criteria,
            { order_by => 'me.id desc', } );
        return $changes;
    }

    return;
}

1;
