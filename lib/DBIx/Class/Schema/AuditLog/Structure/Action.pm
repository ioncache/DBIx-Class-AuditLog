package DBIx::Class::Schema::AuditLog::Structure::Action;

use base 'DBIx::Class::Schema::AuditLog::Structure::Base';

use strict;
use warnings;

__PACKAGE__->table('audit_log_action');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'integer',
        'is_auto_increment' => 1,
        'is_nullable'       => 0,
    },
    'changeset' => {
        'data_type'   => 'integer',
        'is_nullable' => 0,
    },
    'audited_table' => {
        'data_type'   => 'integer',
        'is_nullable' => 0,
    },
    'audited_row' => {
        'data_type'   => 'integer',
        'is_nullable' => 0,
    },
    'type' => {
        'data_type'   => 'varchar',
        'is_nullable' => 0,
        'size'        => 10,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    'Changeset',
    'DBIx::Class::Schema::AuditLog::Structure::Changeset',
    { 'foreign.id' => 'self.changeset' },
);

__PACKAGE__->belongs_to(
    'AuditedTable',
    'DBIx::Class::Schema::AuditLog::Structure::AuditedTable',
    { 'foreign.id' => 'self.audited_table' },
);

__PACKAGE__->has_many(
    'Change',
    'DBIx::Class::Schema::AuditLog::Structure::Change',
    { 'foreign.action' => 'self.id' },
);

1;
