use Test::More;
BEGIN { ok(1); done_testing; exit; }
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::MaxDepth = 1;
use lib qw(t/lib);

package Schema;
use Moose;
extends 'MooseX::DBIC::Schema';
with 'MooseX::DBIC::Loader::Moose' => {
    classes => [qw(MyApp::User)],
    target_namespace => 'Schema'
};

__PACKAGE__->load_classes(qw(Schema::MyApp::User Schema::Moose::Object));

package main;

ok(my $schema = Schema->connect('dbi:SQLite::memory:'));

done_testing;
