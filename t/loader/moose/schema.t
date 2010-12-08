use lib qw(t/lib);
use Test::More;
BEGIN { ok(1); done_testing; exit; }
use SQL::Translator;
use MySchema;

my $schema = MySchema->connect( 'dbi:SQLite::memory:' );

$schema->deploy;

ok(my $user = $schema->resultset('MyApp::User')->create({}));

$user = $schema->resultset('MyApp::User')->first;

isa_ok($user, 'MyApp::User');

ok($user->first('peter'));

ok($user->update);

ok($user->id, 'id is set');

ok($schema->source('MySchema::MyApp::User'), 'Find source by Moose class');


done_testing;