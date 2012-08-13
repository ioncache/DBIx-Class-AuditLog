package DBIx::Class::Schema::AuditLog::Structure::Changeset;

use base 'DBIx::Class::Schema::AuditLog::Structure::Base';

use strict;
use warnings;

__PACKAGE__->load_components(qw< TimeStamp >);

__PACKAGE__->table('audit_log_changeset');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'integer',
        'is_auto_increment' => 1,
        'is_nullable'       => 0,
    },
    'description' => {
        'data_type'   => 'varchar',
        'is_nullable' => 1,
        'size'        => 255,
    },
    'timestamp' => {
        'data_type'     => 'timestamp',
        'set_on_create' => 1,
        'is_nullable'   => 0,
    },
    'user' => {
        'data_type'   => 'integer',
        'is_nullable' => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    'User',
    'DBIx::Class::Schema::AuditLog::Structure::User',
    { 'foreign.id' => 'self.user' },
);

__PACKAGE__->has_many(
    'Action',
    'DBIx::Class::Schema::AuditLog::Structure::Action',
    { 'foreign.changeset' => 'self.id' },
);

1;
