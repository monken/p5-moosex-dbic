package MooseX::DBIC::Meta::Role::ResultProxy;
use Moose::Role;

package MooseX::DBIC::ResultProxy;

use Moose;
use MooseX::ClassAttribute;
use List::Util qw(first);
use Carp;
use Data::Dumper;

sub BUILD {
    croak "ResultProxy cannot be instanciated";
}

sub build_proxy {
    my ( $class, $superclass, %args ) = @_;
    my ( $copy, $builder ) = ( $args{copy}, $args{builder} );
    my $proxy_class = $superclass->meta->create_anon_class(
        superclasses => [$superclass],
        roles        => [qw(MooseX::DBIC::Meta::Role::ResultProxy)],
        methods      => {
            _build_class => sub {
                my ( $self, $method ) = ( shift, shift );
                my $new = $builder->( $self, $superclass );
                bless $self, $superclass;
                %$self = %$new;
                return $new->$method(@_);
              }
        }
    );

    map {
        $proxy_class->add_attribute(
            $_->name => %$_, required => 0)
    }
    $superclass->meta->get_all_attributes;
    
    my @methods =
      map { $_->name }
      map { @{ $_->associated_methods } } $proxy_class->get_all_columns, $proxy_class->get_all_relationships;
    foreach my $method (@methods) {
        next if ( first { $method eq $_ } @$copy );
        $proxy_class->remove_method($method);
        $proxy_class->add_method(
            $method => sub { shift->_build_class( $method, @_ ) } );
    }
    $proxy_class->make_immutable;
    return $proxy_class;
}

1;

__END__

=head1 SYNOPSIS

  MooseX::DBIC::ResultProxy->build_proxy(
    'MySchema::User',
    copy    => [qw(id)],
    builder => sub {
        my ($self, $superclass) = @_;
        return $schema->resultset($superclass)->find($self->id);
    }
  );
