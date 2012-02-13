package DBIx::Class::Schema::AuditLog::User;

use base 'DBIx::Class::Core';

use strict;
use warnings;

__PACKAGE__->table('audit_log_user');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'integer',
        'is_auto_increment' => 1,
        'is_foreign_key'    => 0,
        'is_nullable'       => 0,
        'name'              => 'id',
    },
    'name' => {
        'data_type'      => 'varchar',
        'is_foreign_key' => 0,
        'is_nullable'    => 0,
        'name'           => 'name',
        'size'           => 100,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    'Changeset',
    'DBIx::Class::Schema::AuditLog::Changeset',
    { 'foreign.user' => 'self.id' },
);

1;