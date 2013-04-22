package DBIx::Class::Schema::AuditLog::Structure::User;

use base 'DBIx::Class::Schema::AuditLog::Structure::Base';

use strict;
use warnings;

__PACKAGE__->table('audit_log_user');

__PACKAGE__->add_columns(
    'id' => {
        'data_type'         => 'integer',
        'is_auto_increment' => 1,
        'is_nullable'       => 0,
    },
    'name' => {
        'data_type'   => 'varchar',
        'is_nullable' => 0,
        'size'        => 100,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint( constraint_name => [qw/name/], );

__PACKAGE__->has_many(
    'Changeset',
    'DBIx::Class::Schema::AuditLog::Structure::Changeset',
    { 'foreign.user_id' => 'self.id' },
);

1;
