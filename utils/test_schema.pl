#/usr/bin/env perl

use Modern::Perl;

use Data::Printer;
use Try::Tiny;

use lib '../lib';
use AuditTest::Schema;
use DBIx::Class::AuditLog;

my $schema = AuditTest::Schema->connect( "DBI:mysql:database=audit_test",
    "root", "angU1da", { RaiseError => 1, PrintError => 1 } );

#my $user = $schema->resultset('User')->first();
#p $user;

#$schema->audit_log_schema->deploy;

$schema->txn_do(
    sub {
        $schema->resultset('User')->create(
            {   name  => "JohnSample",
                email => 'jsample@sample.com',
                phone => '999-888-7777',
            }
        );
    },
    {   description => "adding new user: JohnSample",
        user        => "TestAdminUser",
    },
);

$schema->txn_do(
    sub {
        my $user
            = $schema->resultset('User')->search( { name => "JohnSample" } )
            ->first;
        $user->email('johnsample@sample.com');
        $user->update();
    },
    {   description => "updating username: JaneSample",
        user        => "TestAdminUser",
    },
);

$schema->txn_do(
    sub {
        $schema->resultset('User')->search( { name => "JohnSample" } )
            ->first->delete;
    },
    {   description => "delete user: JohnSample",
        user        => "YetAnotherAdminUser",
    },
);

$schema->txn_do(
    sub {
        $schema->resultset('User')->create(
            {   name  => "TehPnwerer",
                email => 'jeremy@purepwnage.com',
                phone => '999-888-7777',
            }
        );
    },
    { description => "adding new user: TehPwnerer -- no admin user", },
);

$schema->txn_do(
    sub {
        my $superman = $schema->resultset('User')->create(
            {   name  => "Superman",
                email => 'ckent@dailyplanet.com',
                phone => '123-456-7890',
            }
        );
        $superman->update(
            {   name  => "Superman",
                email => 'ckent@dailyplanet.com',
                phone => '123-456-7890',
            }
        );
        my $spiderman = $schema->resultset('User')->create(
            {   name  => "Spiderman",
                email => 'ppaker@dailybugle.com',
                phone => '987-654-3210',
            }
        );
        $schema->resultset('User')->search( { name => "Spiderman" } )
            ->first->update(
            {   name  => "Spiderman",
                email => 'pparker@dailybugle.com',
                phone => '987-654-3210',
            }
            );
        $schema->resultset('User')->search( { name => "TehPnwerer" } )
            ->first->update(
            { name => 'TehPwnerer', phone => '416-123-4567' } );
    },
    {   description => "multi-action changeset",
        user        => "ioncache",
    },
);

$schema->resultset('User')->create(
    {   name  => "NonChangesetUser",
        email => 'ncu@oanda.com',
        phone => '987-654-3210',
    }
);

$schema->txn_do(
    sub {
        $schema->resultset('User')->create(
            {   name  => "Drunk Hulk",
                email => 'drunkhulk@twitter.com',
                phone => '123-456-7890',
            }
        );
        $schema->resultset('User')->search( { name => "Drunk hulk" } )
            ->first->update( { email => 'drunkhulk@everywhere.com' } );
    },
    { user => "markj", },
);

$schema->resultset('User')->search( { name => "NonChangesetUser" } )
    ->first->update( { phone => '543-210-9876' } );

my $atbdu = $schema->resultset('User')->create(
    {   name  => "AboutToBeDeletedUser",
        email => 'atbdu@oanda.com',
        phone => '987-654-3210',
    }
);

$atbdu->delete;

1;
