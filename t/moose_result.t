
use lib qw(t/lib ../DBIC/lib);

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

ok( !$user->first(undef), 'set first name to undef' );

is( $user->first, undef, 'first name is undef' );

ok( $user->has_first, 'user still has first name' );

ok( !$user->clear_first, 'clear first' );

ok (!$user->has_first, 'user has no first name' );

is( $user->first, undef, 'first name is undef' );

is( $user->dbic_result->first, undef, 'first name undef on dbic class' );

isa_ok( $user->update, 'MySchema::MyApp::User');

$user->delete;

$user->insert;

#warn $user->meta->find_attribute_by_name("first")->set_value;

done_testing;
