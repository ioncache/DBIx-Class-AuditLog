use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('AuditTest::Schema');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;

$schema->txn_do(
    sub {
        $schema->resultset('User')->create(
            { name => "JohnSample" }
        );
    },
    { description => "no nesting",
      user        => "TestAdminUser01",
    },
);

is (
    $al_schema->resultset('AuditLogChangeset')->search({
        description => 'no nesting'
    })->single->parent_id,
    undef,
    'no nesting'
);

$schema->txn_do(
    sub {
        $schema->resultset('User')->create(
            { name => "JohnSample" }
        );
        $schema->txn_do(
            sub {
                $schema->resultset('User')->create(
                    { name => "JohnSample" }
                );
                $schema->txn_do(
                    sub {
                        $schema->resultset('User')->create(
                            { name => "JohnSample" }
                        );
                        $schema->txn_do(
                            sub {
                                $schema->resultset('User')->create(
                                    { name => "JohnSample" }
                                );
                            },
                            { description => "nesting level 3",
                              user        => "TestAdminUser01",
                            },
                        );
                    },
                    { description => "nesting level 2",
                      user        => "TestAdminUser01",
                    },
                );
            },
            { description => "nesting level 1",
              user        => "TestAdminUser01",
            },
        );
        $schema->txn_do(
            sub {
                $schema->resultset('User')->create(
                    { name  => "JohnSample" }
                );
            },
            { description => "2nd nesting level 1",
              user        => "TestAdminUser01",
            },
        );
    },
    { description => "parent",
      user        => "TestAdminUser01",
    },
);

my $parent_changeset = $al_schema->resultset('AuditLogChangeset')->search({
    description => 'parent'
})->single;
is ( $parent_changeset->parent_id, undef, 'parent');

is (
    $al_schema->resultset('AuditLogChangeset')->search({
        description => 'nesting level 1'
    })->single->parent_id,
    $parent_changeset->id,
    'nested transaction level 1'
);
is (
    $al_schema->resultset('AuditLogChangeset')->search({
        description => 'nesting level 2'
    })->single->parent_id,
    $al_schema->resultset('AuditLogChangeset')->search({
        description => 'nesting level 1'
    })->single->id,
    'nested transaction level 2'
);
is (
    $al_schema->resultset('AuditLogChangeset')->search({
        description => 'nesting level 3'
    })->single->parent_id,
    $al_schema->resultset('AuditLogChangeset')->search({
        description => 'nesting level 2'
    })->single->id,
    'nested transaction level 3'
);
is (
    $al_schema->resultset('AuditLogChangeset')->search({
        description => '2nd nesting level 1'
    })->single->parent_id,
    $parent_changeset->id,
    '2nd nested transaction level 1'
);

$schema->txn_do(
    sub {
        $schema->resultset('User')->create(
            { name => "JohnSample" }
        );
    },
    { description => "2nd no nesting",
      user        => "TestAdminUser01",
    },
);

is (
    $al_schema->resultset('AuditLogChangeset')->search({
        description => '2nd no nesting'
    })->single->parent_id,
    undef,
    'no nesting again'
);

done_testing();
