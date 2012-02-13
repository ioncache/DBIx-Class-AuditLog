package DBIx::Class::Schema::AuditLog::Table;

use base 'DBIx::Class::Core';

use strict;
use warnings;

__PACKAGE__->table('audit_log_table');

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
        'size'           => 40,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    'Field',
    'DBIx::Class::Schema::AuditLog::Field',
    { 'foreign.table' => 'self.id' },
);

__PACKAGE__->has_many(
    'Field',
    'DBIx::Class::Schema::AuditLog::Field',
    { 'foreign.table' => 'self.id' },
);

1;