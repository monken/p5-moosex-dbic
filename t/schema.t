
use lib qw(t/lib);

use Test::More;
use SQL::Translator;
use MySchema;

my $schema = MySchema->connect( 'dbi:SQLite::memory:' );

$schema->deploy;

ok(my $user = $schema->resultset('MyApp::User')->create({}));

isa_ok($user, 'MyApp::User');

ok($user->first('peter'));

ok($user->update);

is($user->id, 1);

done_testing;