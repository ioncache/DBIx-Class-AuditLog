package DBIx::Class::Schema::AuditLog::Structure::AuditedTable;

use base 'DBIx::Class::Schema::AuditLog::Structure::Base';

use strict;
use warnings;

__PACKAGE__->table('audit_log_table');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'integer',
        'is_auto_increment' => 1,
        'is_nullable'       => 0,
        'name'              => 'id',
    },
    'name' => {
        'data_type'   => 'varchar',
        'is_nullable' => 0,
        'name'        => 'name',
        'size'        => 40,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint( [qw/name/] );

__PACKAGE__->has_many(
    'Field',
    'DBIx::Class::Schema::AuditLog::Structure::Field',
    { 'foreign.audited_table_id' => 'self.id' },
);

__PACKAGE__->has_many(
    'Action',
    'DBIx::Class::Schema::AuditLog::Structure::Action',
    { 'foreign.audited_table_id' => 'self.id' },
);

1;
