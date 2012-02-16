package DBIx::Class::Schema::AuditLog::Structure;

use base 'DBIx::Class::Schema';

__PACKAGE__->mk_group_accessors( simple => 'current_user' );
__PACKAGE__->mk_group_accessors( simple => '_current_changeset_container' );

require DBIx::Class::Schema::AuditLog::Structure::Action;
require DBIx::Class::Schema::AuditLog::Structure::AuditedTable;
require DBIx::Class::Schema::AuditLog::Structure::Change;
require DBIx::Class::Schema::AuditLog::Structure::Changeset;
require DBIx::Class::Schema::AuditLog::Structure::Field;
require DBIx::Class::Schema::AuditLog::Structure::User;

sub _current_changeset {
    my $self = shift;
    my $ref  = $self->_current_changeset_container;
    $ref && $ref->{changeset};
}

sub current_changeset {
    my ( $self, @args ) = @_;

    $self->throw_exception(
        'setting current_changeset is not supported, use txn_do to create a new changeset'
    ) if @args;

    my $id = $self->_current_changeset;

    $self->throw_exception(
        q{Can't call current_changeset outside of a transaction})
        unless $id;

    return $id;
}

sub audit_log_create_changeset {
    my ( $self, @args ) = @_;

    my $changeset_data = shift @args;

    my $user = $self->resultset('AuditLogUser')
        ->find_or_create( { name => $changeset_data->{user} } );

    my $changeset = $user->create_related( 'Changeset',
        { description => $changeset_data->{description} } );

    return $changeset;
}

sub audit_log_create_action {
    my $self = shift;

    my $action_data = $_[0];

    my $table = $self->resultset('AuditLogAuditedTable')
        ->find_or_create( { name => $action_data->{table} } );

    return $self->resultset('AuditLogChangeset')
        ->find( $self->current_changeset )->create_related(
        'Action',
        {   audited_row   => $action_data->{row},
            audited_table => $table->id,
            type          => $action_data->{type},
        }
        );

}

1;
