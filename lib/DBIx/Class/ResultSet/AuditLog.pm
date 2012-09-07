package DBIx::Class::ResultSet::AuditLog;

use strict;
use warnings;

use base DBIx::Class::ResultSet;

=head1 NAME

DBIx::Class::ResultSet::AuditLog - ResultSet base class for DBIx::Class::AuditLog

=head1 VERSION

version 0.1

=head1 SYNOPSIS

=head1 L<DBIx::Class::ResultSet> OVERRIDDEN METHODS

=head2 delete

Calls L<DBIx::Class::ResultSet/delete_all> to ensure that triggers defined by
L<DBIx::Class::AuditLog> are run.

=cut

sub delete {
	shift->delete_all;
}

=head2 update

Calls L<DBIx::Class::ResultSet/update_all> to ensure that triggers defined by
L<DBIx::Class::AuditLog> are run.

=cut

sub update {
	shift->update_all(@_);
}

=head1 AUTHORS

See L<DBIx::Class::AuditLog/AUTHOR> and L<DBIx::Class::AuditLog/CONTRIBUTORS>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Jubenville.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
1;


