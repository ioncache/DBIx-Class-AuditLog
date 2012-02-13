package DBIx::Class::AuditLog;

use base qw/DBIx::Class/;

use strict;
use warnings;

use Data::Dump qw/dump/;

our $VERSION = '0.010000';

sub insert {
    my $self = shift;



    return if $self->in_storage;

    my $result = $self->next::method(@_);

    $self->_audit_log_insert;

    return $result;

}

sub audit_log_insert {
    my $self = shift;

    if ( $self->in_storage ) {
        
    }

}

sub update {
    my $self = shift;
warn dump($self);
    return $self->next::method(@_);
}

1;