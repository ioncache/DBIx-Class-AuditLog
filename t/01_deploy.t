use strict;
use warnings;

use Data::Printer;
use DBICx::TestDatabase;
use Test::More;

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('AuditTest::Schema');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;

my $al_user = $al_schema->resultset('AuditLogUser')->create({ name => "TestUser" });

isa_ok($al_user, "DBIx::Class::Schema::AuditLog::Structure::User", "Audit Log User created.");

done_testing();
