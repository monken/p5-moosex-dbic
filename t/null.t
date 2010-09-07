package MySchema::MyClass;
use MooseX::DBIC;

has_column foo => ( is => 'rw', clearer => 'clear_foo' );

__PACKAGE__->meta->make_immutable;

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';
__PACKAGE__->load_classes('MyClass');

package main;
use Test::More;

my $schema = MySchema->connect('dbi:SQLite::memory:');
$schema->deploy;
my $rs = $schema->resultset('MyClass');

{
    my $foo = $rs->create( { foo => 'bar' } );
    $foo->meta->get_column('foo')->clear_value($foo);
    $foo->update;
    ok(!$rs->first->foo, undef);
    $foo->delete;
}

{
    my $foo = $rs->create( { foo => 'bar' } );
    $foo->clear_foo;
    $foo->update;
    ok(!$rs->first->foo, undef);
    $foo->delete;
}

{
    my $foo = $rs->create( { foo => 'bar' } );
    $foo->update( { foo => undef } );
    ok(!$rs->first->foo, undef);
    $foo->delete;
}

done_testing;
