use strict;
use warnings;

use Data::Printer;
use DBICx::TestDatabase;
use Test::More 'no_plan';

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('AuditTest::Schema');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;

p $al_schema->storage->dbh->tables;


done_testing();
