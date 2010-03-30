
use lib qw(t/lib);

use Test::More;
use SQL::Translator;
use MySchema;


my $schema = MySchema->connect( 'dbi:SQLite::memory:' );

$schema->deploy;

ok(MySchema::MyApp::User->meta->meta->does_role('MooseX::DBIC::Meta::Role::Class'));

#ok(my $admin = $schema->resultset('MyApp::User::Admin')->create({ level => 99 }));

ok(my $user = $schema->resultset('MyApp::User')->create({ first => 'Moritz', last => 'Onken'}));

ok($user =  $schema->resultset('MyApp::User')->first);

#ok($admin->isa(ref $user), 'admin isa user');

done_testing;