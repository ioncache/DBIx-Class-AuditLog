use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('AuditTest::Schema');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;

my $test_user;

$schema->txn_do(
    sub {
        $test_user = $schema->resultset('User')->create(
            {   name  => "JohnSample",
                email => 'jsample@sample.com',
                phone => '999-888-7777',
            }
        );
    },
    {   description => "adding new user: JohnSample",
        user        => "TestAdminUser01",
    },
);

my @change_fields = qw< name phone >;    # the email field isn't being logged

foreach my $field (@change_fields) {
    my $change = $al_schema->get_changes(
        { id => $test_user->id, table => 'user', field => $field } )->first;
    ok( defined $change->new_value && !defined $change->old_value,
        "After insert change for field '$field'\t: old_value = '"
            . ( $change->old_value ? $change->old_value : '' )
            . "', new_value = '"
            . ( $change->new_value ? $change->new_value : '' ) . "'"
    );
}

$al_schema->resultset('AuditLogChangeset')->delete_all;

$schema->txn_do(
    sub {
        $test_user
            = $schema->resultset('User')->find( { name => "JohnSample" } )
            ->update(
            {   name  => 'JaneSample',
                phone => '123-456-7890',
            }
            );
    },
    {   description => "updating user: JohnSample",
        user        => "TestAdminUser02",
    },
);

foreach my $field (@change_fields) {
    my $change = $al_schema->get_changes(
        { id => $test_user->id, table => 'user', field => $field } )->first;
    ok( defined $change->new_value && defined $change->old_value,
        "After update change for field '$field'\t: old_value = '"
            . ( $change->old_value ? $change->old_value : '' )
            . "', new_value = '"
            . ( $change->new_value ? $change->new_value : '' ) . "'"
    );
}

$al_schema->resultset('AuditLogChangeset')->delete_all;

my $test_user_id = $test_user->id;

$schema->txn_do(
    sub {
        $test_user->delete;
    },
    {   description => "deleting user: JaneSample",
        user        => "TestAdminUser03",
    },
);

foreach my $field (@change_fields) {
    my $change = $al_schema->get_changes(
        { id => $test_user_id, table => 'user', field => $field } )->first;
    ok( defined $change->old_value,
        "After delete change for field '$field'\t: old_value = '"
            . ( $change->old_value ? $change->old_value : '' )
            . "', new_value = '"
            . ( $change->new_value ? $change->new_value : '' ) . "'"
    );
}

is $al_schema->resultset("AuditLogField")->search( { name => "email" } )
    ->count, 0, "Email field hasn't been added to AuditLogField table.";

my $change = $al_schema->get_changes(
    { id => $test_user->id, table => 'user', field => "email" } );
is $change->count, 0, "Getting changes on field 'email' returns 0 when calling get_changes.";

done_testing();
