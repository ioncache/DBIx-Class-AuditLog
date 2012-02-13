package DBIx::Class::Schema::AuditLog;

use base qw/DBIx::Class::Schema/;

use strict;
use warnings;

use DBIx::Class::Schema::AuditLog::Changeset;
use DBIx::Class::Schema::AuditLog::User;
use Try::Tiny;

__PACKAGE__->register_class('Changeset', 'DBIx::Class::Schema::AuditLog::Changeset');
__PACKAGE__->register_class('User', 'DBIx::Class::Schema::AuditLog::User');

__PACKAGE__->mk_classdata('xxx');


sub install {
    my $self = shift;

}


sub txn_do {
    my ( $self, $user_code, @args ) = @_;



    return $self->next::method( $user_code, @args );


}


1;