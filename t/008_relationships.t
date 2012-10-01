use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('AuditTestRel::Schema');

isa_ok($schema, 'DBIx::Class::Schema::AuditLog');

$schema->populate( 'Person',[
['id', 'name'],
[ 1, 'Fooman'],
[ 2, 'Barwoman'],
]);
$schema->populate( 'Title',[
['id', 'name'],
[ 1, 'CommonTitle'],
[ 2, 'SpecialTitle'],
]);
$schema->populate( 'Book',[
['id', 'title_id', 'isbn'],
[ 1, 1,'12345'],
[ 2, 1,'54321'],
[ 3, 2,'11223'],
]);
$schema->populate( 'BookAuthor',[
['book_id', 'author_id'],
[ 1, 1,],
[ 2, 1,],
[ 3, 2,],
[ 3, 1,],
]);

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;

done_testing;
