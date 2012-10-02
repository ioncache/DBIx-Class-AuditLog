use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;
use lib 't/lib';

eval "use DBIx::Class::ResultSet::RecursiveUpdate";
plan skip_all => 'DBIx::Class::ResultSet::RecursiveUpdate is required to run this test' if $@;


my $schema = DBICx::TestDatabase->new('AuditTestRU::Schema');

isa_ok($schema, 'DBIx::Class::Schema::AuditLog');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;
my $changesets = $al_schema->resultset('AuditLogChangeset');

my $books_rs = $schema->resultset('Book');

isa_ok($books_rs, 'DBIx::Class::ResultSet::RecursiveUpdate');
isa_ok($books_rs, 'DBIx::Class::ResultSet::AuditLog');

my $book_data_1 = {
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
	$books_rs->recursive_update($book_data_1);
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

done_testing;
