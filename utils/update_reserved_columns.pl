#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use Getopt::Long::Descriptive;
use Try::Tiny;

my ( $opt, $usage ) = describe_options(
    "$0 %o",
    [ 'dsn|s=s',  'Database source name (dsn) to connect to' ],
    [ 'user|u=s', 'Database username' ],
    [ 'pass|p=s', 'Database password' ],
    [],
    [ 'help|h', 'Print usage message and exit' ],
);

print( $usage->text ), exit if $opt->help or !$opt->dsn;

my $dbh
    = DBI->connect( $opt->dsn, $opt->user, $opt->pass,
    { RaiseError => 1, AutoCommit => 0 } )
    or die $DBI::errstr;

try {
    my %update = map { $_ => \&$_ } qw/ default mysql pg /;
    my $code_ref = $update{ lc $dbh->{Driver}{Name} } || $update{'default'};
    $code_ref->($dbh);
    $dbh->commit;
}
catch {
    warn "Database definition update aborted: $_";
    $dbh->rollback;
};

sub default {
    my $dbh = shift;
    my @sql = (

        # audit_log_changeset
        'ALTER TABLE audit_log_changeset RENAME COLUMN "USER" TO "USER_ID"',
        'ALTER TABLE audit_log_changeset RENAME COLUMN "TIMESTAMP" TO "CREATED_ON"',

        # audit_log_action
        'ALTER TABLE audit_log_action RENAME COLUMN "CHANGESET" TO "CHANGESET_ID"',
        'ALTER TABLE audit_log_action RENAME COLUMN "AUDITED_TABLE" TO "AUDITED_TABLE_ID"',
        'ALTER TABLE audit_log_action RENAME COLUMN "TYPE" TO "ACTION_TYPE"',

        # audit_log_change
        'ALTER TABLE audit_log_change RENAME COLUMN "ACTION" TO "ACTION_ID"',
        'ALTER TABLE audit_log_change RENAME COLUMN "FIELD" TO "FIELD_ID"',

        # audit_log_field
        'ALTER TABLE audit_log_field RENAME COLUMN "AUDITED_TABLE" TO "AUDITED_TABLE_ID"',
    );

    $dbh->do($_) for @sql;
}

sub pg {
    my $dbh = shift;
    my @sql = (

        # audit_log_changeset
        'ALTER TABLE audit_log_changeset RENAME COLUMN "user" TO "user_id"',
        'ALTER TABLE audit_log_changeset RENAME COLUMN "timestamp" TO "created_on"',

        # audit_log_action
        'ALTER TABLE audit_log_action RENAME COLUMN "changeset" TO "changeset_id"',
        'ALTER TABLE audit_log_action RENAME COLUMN "audited_table" TO "audited_table_id"',
        'ALTER TABLE audit_log_action RENAME COLUMN "type" TO "action_type"',

        # audit_log_change
        'ALTER TABLE audit_log_change RENAME COLUMN "action" TO "action_id"',
        'ALTER TABLE audit_log_change RENAME COLUMN "field" TO "field_id"',

        # audit_log_field
        'ALTER TABLE audit_log_field RENAME COLUMN "audited_table" TO "audited_table_id"',
    );

    $dbh->do($_) for @sql;
}

sub mysql {
    my $dbh = shift;

    my @sql = (

        # audit_log_changeset
        'ALTER TABLE `audit_log_changeset` DROP FOREIGN KEY `audit_log_changeset_fk_user`',
        'ALTER TABLE `audit_log_changeset` CHANGE COLUMN `timestamp` `created_on` TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
            CHANGE COLUMN `user` `user_id` INTEGER  DEFAULT NULL,
            DROP INDEX `audit_log_changeset_idx_user`,
            ADD INDEX `audit_log_changeset_idx_user` USING BTREE(`user_id`),
            ADD CONSTRAINT `audit_log_changeset_fk_user` FOREIGN KEY `audit_log_changeset_fk_user` (`user_id`)
                REFERENCES `audit_log_user` (`id`)
                ON DELETE CASCADE
                ON UPDATE CASCADE',

        # audit_log_action
        'ALTER TABLE `audit_log_action` DROP FOREIGN KEY `audit_log_action_fk_audited_table`',
        'ALTER TABLE `audit_log_action` DROP FOREIGN KEY `audit_log_action_fk_changeset`',
        'ALTER TABLE `audit_log_action` CHANGE COLUMN `changeset` `changeset_id` INTEGER  NOT NULL,
            CHANGE COLUMN `audited_table` `audited_table_id` INTEGER  NOT NULL,
            DROP INDEX `audit_log_action_idx_audited_table`,
            ADD INDEX `audit_log_action_idx_audited_table` USING BTREE(`audited_table_id`),
            DROP INDEX `audit_log_action_idx_changeset`,
            ADD INDEX `audit_log_action_idx_changeset` USING BTREE(`changeset_id`),
            ADD CONSTRAINT `audit_log_action_fk_audited_table` FOREIGN KEY `audit_log_action_fk_audited_table` (`audited_table_id`)
               REFERENCES `audit_log_table` (`id`)
               ON DELETE CASCADE
               ON UPDATE CASCADE,
            ADD CONSTRAINT `audit_log_action_fk_canngeset` FOREIGN KEY `audit_log_action_fk_canngeset` (`changeset_id`)
               REFERENCES `audit_log_changeset` (`id`)
               ON DELETE CASCADE
               ON UPDATE CASCADE',
        'ALTER TABLE `audit_log_action CHANGE COLUMN `type` `action_type` VARCHAR(10) NOT NULL',

        # audit_log_change
        'ALTER TABLE `audit_log_change` DROP FOREIGN KEY `audit_log_change_fk_action`',
        'ALTER TABLE `audit_log_change` DROP FOREIGN KEY `audit_log_change_fk_field`',

        'ALTER TABLE `audit_log_change` CHANGE COLUMN `action` `action_id` INTEGER  NOT NULL,
            CHANGE COLUMN `field` `field_id` INTEGER  NOT NULL,
            DROP INDEX `audit_log_change_idx_action`,
            ADD INDEX `audit_log_change_idx_action` USING BTREE(`action_id`),
            DROP INDEX `audit_log_change_idx_field`,
            ADD INDEX `audit_log_change_idx_field` USING BTREE(`field_id`),
            ADD CONSTRAINT `audit_log_change_fk_action` FOREIGN KEY `audit_log_change_fk_action` (`action_id`)
                REFERENCES `audit_log_action` (`id`)
                ON DELETE CASCADE
                ON UPDATE CASCADE,
            ADD CONSTRAINT `audit_log_change_fk_field` FOREIGN KEY `audit_log_change_fk_field` (`field_id`)
                REFERENCES `audit_log_field` (`id`)
                ON DELETE CASCADE
                ON UPDATE CASCADE',

        # audit_log_field
        'ALTER TABLE `audit_log_field` DROP FOREIGN KEY `audit_log_field_fk_audited_table`',

        'ALTER TABLE `audit_log_field` CHANGE COLUMN `audited_table` `audited_table_id` INTEGER  NOT NULL,
            DROP INDEX `audit_log_field_idx_audited_table`,
            ADD INDEX `audit_log_field_idx_audited_table` USING BTREE(`audited_table_id`),
            ADD CONSTRAINT `audit_log_field_fk_audited_table` FOREIGN KEY `audit_log_field_fk_audited_table` (`audited_table_id`)
                REFERENCES `audit_log_table` (`id`)
                ON DELETE CASCADE
                ON UPDATE CASCADE',
    );

    $dbh->do($_) for @sql;
}
