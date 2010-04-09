use MooseX::Attribute::Deflator::Moose;

package MyClass;
use MooseX::DBIC;


has_column foo => ( is => 'rw' );
has_column bar => ( is => 'rw', required => 1 );

package main;
use Test::More;
use Test::Exception;

use MooseX::DBIC::ResultProxy;


throws_ok {my $proxy  = MooseX::DBIC::ResultProxy->new } qr/subclass/, 'need subclassing';

ok( my $proxy_class = MooseX::DBIC::ResultProxy->build_proxy( 
    MyClass => 
        ( copy => [ qw(foo) ], 
          builder => sub {
            my ($self, $class) = @_;
            return $class->new(%$self, bar => 'lazy', '-result_source' => 'foo');
          } ) )
);

ok( my $proxy = $proxy_class->name->new( foo => 'bar' ), 'MyProxy instance' );
is( $proxy->foo, 'bar');
like( ref $proxy, qr/ANON/, 'proxy is an anon class' );
is( $proxy->bar, 'lazy');
is( ref $proxy, 'MyClass', 'proxy is MyClass' );
done_testing;
