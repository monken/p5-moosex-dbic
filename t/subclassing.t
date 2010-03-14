
use lib qw(t/lib ../inflate_result/lib);

use Test::More;
use SQL::Translator;
use MySchema;


MySchema->load_classes('MyApp::User::Admin');
my $schema = MySchema->connect( 'dbi:SQLite::memory:' );

$schema->deploy;

ok(my $user = $schema->resultset('MyApp::User')->create({}));

done_testing;