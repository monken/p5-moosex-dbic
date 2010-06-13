use SQL::Translator;
use lib qw(t/lib);
use Pad::Schema;
use DateTime;
use Benchmark qw(:all);
use Data::Dumper;

my $schema = Pad::Schema->connect( 'dbi:SQLite::memory:' );
$schema->deploy;

$schema->resultset('Release')->create({ author => { name => 'me' }, distribution => { name => 'Test' },  uploaded => DateTime->now })
    for(1..100);


print "Inserted 100 results", $/;
DB::enable_profile();

cmpthese(15, {
    MXDBIC => sub { $schema->resultset('Release')->all; },
    #'Moose::Object' => sub { Moose::Object->new for(1..100) },
    #DBI => sub { $schema->storage->dbh->selectall_hashref('SELECT me.resources, me.author, me.distribution, me.uploaded, me.id FROM release me', 'id'); },
    #DateTime => sub { DateTime->now for(1..100) }
});

done_testing;
