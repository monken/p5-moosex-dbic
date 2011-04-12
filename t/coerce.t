use Test::More;
use strict;
use warnings;

use Moose::Util::TypeConstraints;

subtype 'C', as 'ArrayRef';
coerce 'C', from 'Str', via { [ $_ ] };

no Moose::Util::TypeConstraints;

package TestRole;
use Moose::Role;
use MooseX::DBIC;
has_column attr => ( is => 'rw', coerce => 1, isa => 'C' );

package Test;
use Moose;
use MooseX::DBIC;
with 'TestRole';

package main;

for ( 1 .. 2 ) {

    my $foo = Test->new( attr => "foo", -result_source => 1 );
    is_deeply(Test->meta->get_attribute('attr')->get_raw_value($foo), ["foo"], 'raw value is arrayref');
    is_deeply( $foo->attr, ["foo"], 'attribute has been coerced' );
    ok( Test->meta->get_attribute('attr')->is_inflated($foo) );

    $foo = Test->new( attr => ['foo'], -result_source => 1 );
    is_deeply(Test->meta->get_attribute('attr')->get_raw_value($foo), ["foo"], 'raw value is arrayref');
    is_deeply( $foo->attr, ["foo"], 'attribute has been coerced' );
    ok( Test->meta->get_attribute('attr')->is_inflated($foo) );
    Test->meta->make_immutable;

}

done_testing;
