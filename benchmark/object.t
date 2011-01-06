use SQL::Translator;
use lib qw(t/lib benchmark/lib);
use Pad::Schema;
use DateTime;
use Benchmark qw(:all);
use Data::Dumper;
use DBIC::Schema;
use Moose::Release;
use strict;
use warnings;

BEGIN {
    delete $ENV{DBIC_TRACE};
};

my $mschema = Pad::Schema->connect( 'dbi:SQLite::memory:' );
my $dbicschema = DBIC::Schema->connect( 'dbi:SQLite::memory:' );

foreach my $schema ($mschema, $dbicschema) {
$schema->deploy;
}

my $create = { author => { name => 'me' }, distribution => { name => 'Test' },  uploaded => DateTime->now };

cmpthese(200, {
 MXDBIC => sub { $mschema->resultset('Release')->create($create); },
 DBIC => sub { $dbicschema->resultset('Release')->create($create); },
});

print "Inserted 100 results", $/;
#DB::enable_profile();
#$mschema->resultset('Release')->all for(1..50);
#die;

cmpthese(50, {
    MXDBIC => sub { $mschema->resultset('Release')->all; },
    DBIC => sub { $dbicschema->resultset('Release')->all; },
    Moose => sub { Moose::Release->new( id => 1, author => 1, distribtution => 1, uploaded => 1 ) for(1..100) },
    DBI => sub { $mschema->storage->dbh->selectall_hashref('SELECT me.resources, me.author, me.distribution, me.uploaded, me.id FROM release me', 'id'); },
    DateTime => sub { DateTime->now for(1..200) }
});


my @mxall = $mschema->resultset('Release')->all;
my @dbicall = $dbicschema->resultset('Release')->all;

#DB::enable_profile();

cmpthese(50, {
    MXDBIC => sub { map { $_->update } @mxall; },
    DBIC => sub { map { $_->update } @dbicall; },
});
