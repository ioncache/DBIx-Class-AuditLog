package DBIx::Class::Schema::AuditLog::Changeset;

use base 'DBIx::Class::Core';

use strict;
use warnings;

__PACKAGE__->table('audit_log_changeset');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'integer',
        'is_auto_increment' => 1,
        'is_foreign_key'    => 0,
        'is_nullable'       => 0,
        'name'              => 'id',
    },
    'description' => {
        'data_type'      => 'varchar',
        'is_foreign_key' => 0,
        'is_nullable'    => 1,
        'name'           => 'description',
    },
    'timestamp' => {
        'data_type'      => 'timestamp',
        'is_foreign_key' => 0,
        'is_nullable'    => 0,
        'name'           => 'timestamp',
    },
    'user' => {
        'data_type'      => 'integer',
        'is_foreign_key' => 1,
        'is_nullable'    => 0,
        'name'           => 'user',
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    'User',
    'DBIx::Class::Schema::AuditLog::User',
    { 'foreign.id' => 'self.user' },
);

__PACKAGE__->has_many(
    'Action',
    'DBIx::Class::Schema::AuditLog::Action',
    { 'foreign.changeset' => 'self.id' },
);

1;