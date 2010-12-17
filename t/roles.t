use MooseX::Attribute::Deflator::Moose;

package MyRole;
use MooseX::DBIC::Role;

has_column 'role';
belongs_to hasmany => ( isa => 'HasMany' );

package MyClass;
use MooseX::DBIC;
with 'MyRole';

has_column foo => ( is => 'rw' );
has_column bar => ( is => 'rw', required => 1 );

__PACKAGE__->meta->make_immutable;

package HasMany;
use MooseX::DBIC;
with 'MyRole';

has_many classes => ( isa => 'MyClass', foreign_key => 'hasmany' );

__PACKAGE__->meta->make_immutable;

package main;
use Test::More;

ok( MyClass->meta->get_column('id')->does('MooseX::DBIC::Meta::Role::Column') );
ok( MyClass->meta->get_column('role')->does('MooseX::DBIC::Meta::Role::Column')
);
ok( MyClass->meta->get_column('hasmany') );
ok( MyClass->meta->get_column('hasmany')->foreign_key );
ok( MyClass->meta->get_relationship('hasmany') );

ok( HasMany->meta->get_relationship('classes')->foreign_key );

ok( MyClass->meta->get_column('id')->primary_key );


my $foo = MyClass->new( -result_source => 1 );
ok( $foo->id );
done_testing;
