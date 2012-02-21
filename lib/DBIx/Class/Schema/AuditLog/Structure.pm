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

1;
