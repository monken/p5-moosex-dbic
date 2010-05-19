package MooseX::DBIC::Meta::Role::ResultProxy;
use Moose::Role;

package MooseX::DBIC::ResultProxy;

use Moose;
use MooseX::ClassAttribute;
use List::Util qw(first);
use Carp; use Data::Dumper;

sub BUILD {
    croak "ResultProxy cannot be instanciated";
}

my @refs;

sub build_proxy {
    my ($class, $superclass, %args) = @_;
    my ($copy, $builder) = ($args{copy}, $args{builder});
    my $proxy_class = Moose::Meta::Class->create_anon_class(
        superclasses => [$superclass],
        roles => [qw(MooseX::DBIC::Meta::Role::ResultProxy)],
        methods => { _build_class => sub {
            my ($self, $method) = (shift, shift);
            my $new = $builder->($self, $superclass);
            bless $self, $superclass;
            %$self = %$new;
            return $new->$method(@_);
        } } );
    
    map { $proxy_class->add_attribute($_->clone_and_inherit_options(required => 0)) } $superclass->meta->get_all_attributes;
    my @methods = map { $_->name } map { @{$_->associated_methods} } $proxy_class->get_all_columns;
    foreach my $method (@methods) {
        next if(first { $method eq $_ } @$copy);
        $proxy_class->add_method(  $method => sub { shift->_build_class($method, @_) }   );
    }
    $proxy_class->make_immutable;
    push(@refs, $proxy_class);
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