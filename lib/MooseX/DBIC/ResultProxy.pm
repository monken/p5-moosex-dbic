package MooseX::DBIC::Meta::Role::ResultProxy;
use Moose::Role;

package MooseX::DBIC::ResultProxy;

use Moose;
use MooseX::ClassAttribute;
use List::Util qw(first);
use Carp; use Data::Dumper;

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
            my ($self, $method) = @_;
            warn $method;
            my $new = $builder->($self, $superclass);
            bless $self, $superclass;
            %$self = %$new;
            return $new->$method;
        } } )->name;
    Class::MOP->load_class($proxy_class);
    map { $proxy_class->meta->add_attribute($_->clone_and_inherit_options(required => 0)) } $superclass->meta->get_all_attributes;
    my @methods = map { $_->name } map { @{$_->associated_methods} } $proxy_class->meta->get_all_attributes;
    use Data::Dumper; warn Dumper \@methods;
    foreach my $method (@methods) {
        next if(first { $method eq $_ } @$copy);
        $proxy_class->meta->add_method(  $method => sub { shift->_build_class($method, @_) }   );
    }
    return $proxy_class;
}

1;