use lib qw(t/lib);

use Test::More;
use SQL::Translator;
use MySchema;

my $schema = MySchema->connect('dbi:SQLite::memory:');

$schema->deploy;

ok(
    my $user = MySchema::MyApp::User->new(
#
        dbic_result => $schema->resultset('MyApp::User')->create( {} )
    ),
    'create a new user'
);
ok( $user->first("abc"), 'set first name' );

is( $user->first, "abc", 'read first name' );

isa_ok( $user->update, 'MySchema::MyApp::User');

$user->delete;

$user->insert;

#warn $user->meta->find_attribute_by_name("first")->set_value;

done_testing;
