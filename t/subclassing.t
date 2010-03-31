
use lib qw(t/lib ../p5-moosex-attribute-deflator/lib);

use Test::More;
use SQL::Translator;
use MySchema;


my $schema = MySchema->connect( 'dbi:SQLite::memory:' );

$schema->deploy;

use Data::Dumper; $Data::Dumper::Indent = 1; $Data::Dumper::Maxdepth = 3; warn Dumper $schema;

ok(my $admin = $schema->resultset('MyApp::User::Admin')->create({ first => 'Moritz', last => 'Onken', level => 99 }));
is($admin->first, 'Moritz');
ok($admin =  $schema->resultset('MyApp::User::Admin')->first);
is($admin->last, 'Onken');
is($admin->level, 99);



ok(my $user = $schema->resultset('MyApp::User')->create({ first => 'Moritz', last => 'Onken'}));

ok($user =  $schema->resultset('MyApp::User')->first);

TODO: {
  local $TODO = "fake ISA";
  ok($admin->isa(ref $user), 'admin isa user');
}

done_testing;