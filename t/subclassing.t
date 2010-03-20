
use lib qw(t/lib ../inflate_result/lib);

use Test::More;
use SQL::Translator;
use MySchema;


my $schema = MySchema->connect( 'dbi:SQLite::memory:' );

$schema->deploy;

ok(my $user = $schema->resultset('MyApp::User::Admin')->create({ level => 99 }));

done_testing;