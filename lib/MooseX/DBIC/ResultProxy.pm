package MooseX::DBIC::Meta::Role::ResultProxy;
use Moose::Role;

package MooseX::DBIC::ResultProxy;

use Moose;
use MooseX::ClassAttribute;
use List::Util qw(first);
use Carp;

sub BUILD {
    croak "ResultProxy needs to be subclassed" unless(shift->meta->superclasses > 1);
}

sub build_proxy {
    my ($class, $superclass, %args) = @_;
    my ($copy, $builder) = ($args{copy}, $args{builder});
    my $proxy_class = Moose::Meta::Class->create_anon_class(
        superclasses => [$superclass],
        roles => [qw(MooseX::DBIC::Meta::Role::ResultProxy)],
        cache => 1,
        methods => { _build_class => sub {
            my ($self, $attr) = @_;
            my $new = $builder->($self, $superclass);
            bless $self, $superclass;
            %$self = %$new;
            return $new->$attr;
        } } )->name;
    Class::MOP->load_class($proxy_class);
    foreach my $attr ($superclass->meta->get_all_attributes) {
        next if(first { $attr->name eq $_ } @$copy);
        $proxy_class->meta->add_attribute( 
          $attr->clone_and_inherit_options(
          required => 1, lazy => 1, default => sub { shift->_build_class($attr->name) } 
        ));
    }
    return $proxy_class;
}

1;