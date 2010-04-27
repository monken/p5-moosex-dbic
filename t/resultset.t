use MooseX::Attribute::Deflator::Moose;

package MyClass::Set;
use Moose;

package MyClass;
use MooseX::DBIC;


has_column foo => ( is => 'rw' );
has_column bar => ( is => 'rw', required => 1 );

package MySchema;
use Moose;
extends 'MooseX::DBIC::Schema';
__PACKAGE__->load_classes('MyClass');

package main;
use Test::More;

my $schema = MySchema->connect('dbi:SQLite::memory:');
isa_ok($schema->resultset('MyClass'), 'MyClass::Set' );

done_testing;
