package DBIx::Class::Schema::AuditLog;

use base qw/DBIx::Class::Schema/;

use strict;
use warnings;

use Class::C3::Componentised ();
use DBIx::Class::Schema::AuditLog::Structure;
use Scalar::Util 'blessed';

__PACKAGE__->mk_classdata('audit_log_connection');
__PACKAGE__->mk_classdata('audit_log_schema');
__PACKAGE__->mk_classdata('audit_log_schema_template');
__PACKAGE__->mk_classdata('audit_log_storage_type');

=head1 DBIx::Class OVERRIDDEN METHODS

=head2 connection

Overrides the DBIx::Class connection method to create an AuditLog schema.

=cut
sub connection {
    my $self = shift;

    my $schema = $self->next::method(@_);

    my $audit_log_schema = ( ref $self || $self )
        ->find_or_create_audit_log_schema_template->clone;

    if ( $self->audit_log_connection ) {
        $audit_log_schema->storage_type( $self->audit_log_storage_type )
            if $self->audit_log_storage_type;
        $audit_log_schema->connection( @{ $self->audit_log_connection } );
    }
    else {
        $audit_log_schema->storage( $schema->storage );
    }

    $self->audit_log_schema($audit_log_schema);

    $self->audit_log_schema->storage->disconnect();

    return $schema;
}

=head2 txn_do

Wraps the DBIx::Class txn_do method with a new changeset whenever required.

=cut
sub txn_do {
    my ( $self, $user_code, @args ) = @_;

    my $audit_log_schema = $self->audit_log_schema;

    my $code = $user_code;

    my $changeset_data = $args[0];

    my $current_changeset = $audit_log_schema->_current_changeset;
    if ( !$current_changeset ) {
        my $current_changeset_ref
            = $audit_log_schema->_current_changeset_container;

        unless ($current_changeset_ref) {
            $current_changeset_ref = {};
            $audit_log_schema->_current_changeset_container(
                $current_changeset_ref);
        }

        $code = sub {
            # creates local variables in the transaction scope to store
            # the changset args, and the changeset id
            local $current_changeset_ref->{args}      = $args[0];
            local $current_changeset_ref->{changeset} = '';
            $user_code->(@_);
        };
    }

    if ( $audit_log_schema->storage != $self->storage ) {
        my $inner_code = $code;
        $code = sub { $audit_log_schema->txn_do( $inner_code, @_ ) };
    }

    return $self->next::method( $code, @args );
}

=head1 HELPER METHODS

=head2 audited_sources

returns the list of sourcenames which have DBIx::Class::AuditLog loaded

=cut

sub audited_sources{
	my $self = shift;
	grep { $self->class($_)->isa("DBIx::Class::AuditLog") }
		$self->sources;
}
	
=head2 audited_source

=over 

=item Arguments: $source_name

=back

Like L<DBIx::Class::Schema/source>, but returns 0 if the resulting source does not have
AuditLog loaded

=cut

sub audited_source {
	my $source = shift->source(@_);

	return $source if $source && $source->isa("DBIx::Class::AuditLog");
	return 0;
}

=head2 find_or_create_audit_log_schema_template

Finds or creates a new schema object using the AuditLog tables.

=cut
sub find_or_create_audit_log_schema_template {
    my $self = shift;

    my $schema = $self->audit_log_schema_template;

    return $schema if $schema;

    my $c = blessed($self) || $self;

    my $class = "${c}::_AUDITLOG";

    Class::C3::Componentised->inject_base( $class,
        'DBIx::Class::Schema::AuditLog::Structure' );

    $schema = $self->audit_log_schema_template(
        $class->compose_namespace( $c . '::AuditLog' ) );

    my $prefix = 'AuditLog';
    foreach my $audit_log_table (
        qw< Action Change Changeset Field AuditedTable User>)
    {
        my $class = blessed($schema) . "::$audit_log_table";

        Class::C3::Componentised->inject_base( $class,
            "DBIx::Class::Schema::AuditLog::Structure::$audit_log_table" );

        $schema->register_class( $prefix . $audit_log_table, $class );

    }

    return $schema;
}

1;
