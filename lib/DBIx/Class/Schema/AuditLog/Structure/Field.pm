package DBIx::Class::Schema::AuditLog::Structure::Field;

use base 'DBIx::Class::Schema::AuditLog::Structure::Base';

use strict;
use warnings;

__PACKAGE__->table('audit_log_field');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'integer',
        'is_auto_increment' => 1,
        'is_nullable'       => 0,
    },
    'audited_table_id' => {
        'data_type'   => 'integer',
        'is_nullable' => 0,
    },
    'name' => {
        'data_type'   => 'varchar',
        'is_nullable' => 0,
        'size'        => 40,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    'AuditedTable',
    'DBIx::Class::Schema::AuditLog::Structure::AuditedTable',
    { 'foreign.id' => 'self.audited_table_id' },
);

__PACKAGE__->has_many(
    'Change',
    'DBIx::Class::Schema::AuditLog::Structure::Change',
    { 'foreign.field_id' => 'self.id' },
);

1;
