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
[ 2, 2,'54321'],
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

my $title1 = $schema->resultset('Title')->find({ name => 'CommonTitle'});
my $title2 = $schema->resultset('Title')->find({ name => 'SpecialTitle'});

my $book1 = $schema->resultset('Book')->find(1);


$schema->txn_do(sub{
	$book1->update_from_related('title', $title2);
},{
});

subtest 'validate changeset after update_from_related' => sub{
	my $changesets = $al_schema->resultset('AuditLogChangeset');
	is($changesets->count, 1, "one changeset after set_from_related");
	is($changesets->first->Action->count, 1, "one action in changeset after set_from_related");
	my $action = $changesets->first->Action->first;
	is($action->AuditedTable->name, 'book', 'Book-table audited');
	is($action->Change->count, 1, 'one change logged');
	my $change = $action->Change->first;
	is($change->Field->name, 'title_id', 'title_id field logged');
	is($change->old_value, 1, 'old value logged correctly');
	is($change->new_value, 2, 'new value logged correctly');

};

$schema->txn_do(sub{
	$title1->create_related('books', { isbn => '12321', });
});

subtest 'validate changeset after create_related' => sub{
	my $changesets = $al_schema->resultset('AuditLogChangeset');
	is($changesets->count, 2, "two changeset after create_related");
	is($changesets->find(2)->Action->count, 1, "one action in changeset after create_related");
	my $action = $changesets->find(2)->Action->first;
	is($action->AuditedTable->name, 'book', 'Book-table audited');
	my $changes = $action->Change;
	is($changes->count, 3, 'three changes logged');
	my $id_field = $al_schema->resultset('AuditLogField')->find({name => 'id', audited_table => 1});
	isa_ok($id_field, 'DBIx::Class::Schema::AuditLog::Structure::Field');
	my $id_change = $changes->find({field => $id_field->id});
	isa_ok($id_change, 'DBIx::Class::Schema::AuditLog::Structure::Change');
	ok(! $id_change->old_value, 'id field has no old value');
	my $isbn_field = $al_schema->resultset('AuditLogField')->find({name => 'isbn', audited_table => 1});
	isa_ok($isbn_field, 'DBIx::Class::Schema::AuditLog::Structure::Field');
	my $isbn_change = $changes->find({field => $isbn_field->id});
	isa_ok($isbn_change, 'DBIx::Class::Schema::AuditLog::Structure::Change');
	ok(! $isbn_change->old_value, 'isbn field has no old value');
	my $title_id_field = $al_schema->resultset('AuditLogField')->find({name => 'title_id', audited_table => 1});
	isa_ok($title_id_field, 'DBIx::Class::Schema::AuditLog::Structure::Field');
	my $title_id_change = $changes->find({field => $title_id_field->id});
	isa_ok($title_id_change, 'DBIx::Class::Schema::AuditLog::Structure::Change');
	ok(! $title_id_change->old_value, 'title_id field has no old value');
	is($title_id_change->new_value, $title1->id, 'new value for title_id is set correctly');
};

my $new_book = $schema->resultset('Book')->find({isbn => '12321'});
$schema->txn_do(sub{
	$new_book->add_to_authors($schema->resultset('Person')->find(1));
});

done_testing;
