use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;
use lib 't/lib';

eval "use DBIx::Class::ResultSet::RecursiveUpdate";
if($@){
	plan skip_all => 'DBIx::Class::ResultSet::RecursiveUpdate is required to run this test';
}else{
	plan tests => 6,
}


my $schema = DBICx::TestDatabase->new('AuditTestRU::Schema');

isa_ok($schema, 'DBIx::Class::Schema::AuditLog');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;
my $changesets = $al_schema->resultset('AuditLogChangeset');

my $books_rs = $schema->resultset('Book');

isa_ok($books_rs, 'DBIx::Class::ResultSet::RecursiveUpdate');
isa_ok($books_rs, 'DBIx::Class::ResultSet::AuditLog');

my $book_data = {
	isbn => '112233',
	title_id => 1,
	authors => [{
		name => 'FooAuthor',
	},
	{
		name => 'BarAuthor',
	},
	],
	title => {
		name => 'NiceTitle',
	}
};

$schema->txn_do(sub{
	$books_rs->recursive_update($book_data);
},
);

subtest 'validate changeset after create with ru' => sub{
	is( $changesets->count, 1, 'one changeset in log');
	my $cset = $changesets->find(1);
	is($cset->Action->count, 6, 'six actions in changeset');
	foreach ($cset->Action->all){
		is($_->type, 'insert', 'all actions are inserts');
	}
};

$book_data = {
	id => 1,
	authors => [ { name => 'FooBarAuthor'}],
	title => { name => 'AnotherTitle'},
};

$schema->txn_do(sub{
	$books_rs->recursive_update($book_data);
},
);

subtest 'validate changeset after first update with ru' => sub{
	is( $changesets->count, 2, 'two changesets in log');
	my $cset = $changesets->find(2);
	is($cset->Action->count, 5, 'five actions in changeset');
	is($cset->Action->search({type => 'delete'})->count, 2, 'two delete actions');
	is($cset->Action->search({type => 'insert'})->count, 2, 'two insert actions');
	is($cset->Action->search({type => 'update'})->count, 1, 'one update action');
};

$book_data = {
	id => 1,
	title_id => 2,
	isbn => '11111',
	authors => [ { name => 'FooBarAuthor'}, { name => 'FooAuthor'}],
	title => { name => 'NiceTitle'},
};

$schema->txn_do(sub{
	$books_rs->recursive_update($book_data);
},
);

subtest 'validate changeset after first update with ru' => sub{
	is( $changesets->count, 3, 'three changesets in log');
	my $cset = $changesets->find(3);
	is($cset->Action->count, 7, 'five actions in changeset');
	is($cset->Action->search({type => 'delete'})->count, 1, 'one delete action');
	is($cset->Action->search({type => 'insert'})->count, 5, 'five insert actions');
	is($cset->Action->search({type => 'update'})->count, 1, 'one update action');
};
