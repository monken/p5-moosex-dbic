use lib qw(t/lib);
use Test::More;
use SQL::Translator;
use MySchema;

my $schema = MySchema->connect('dbi:SQLite::memory:');

$schema->deploy;

ok(my $user = $schema->resultset('MyApp::User')->create({}),
    'create a new user'
);

ok( my $id = $user->id, 'get id' );

ok(  $id eq $user->id, 'id did not change' );

ok( $user->first("abc"), 'set first name' );

is( $user->first, "abc", 'read first name' );

ok ($user->has_first, 'user has first name' );

ok( $user->clear_first, 'clear first' );

ok (!$user->has_first, 'user has no first name' );

is( $user->first, undef, 'first name is undef' );

isa_ok( $user->update, 'MySchema::MyApp::User');

TODO: { local $TODO = 'delete'; eval { $user->delete; } or do { ok(0) } }

$user->insert;

ok($user = $schema->resultset('MyApp::User::Admin')->create({}),
    'create a new user'
);

ok($user->meta->does_role('MyApp::Role::Hair'), 'Moose Result class does role');

done_testing;
