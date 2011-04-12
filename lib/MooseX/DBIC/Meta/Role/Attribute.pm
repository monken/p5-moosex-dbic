package MooseX::DBIC::Meta::Role::Attribute;

use Moose::Role;

with 'MooseX::Attribute::LazyInflator::Meta::Role::Attribute';

after _process_options => sub {
    my ( $class, $name, $options ) = @_;
    if (    $options->{required}
         && !$options->{builder}
         && !defined $options->{default} )
    {
        $options->{lazy}     = 1;
        $options->{required} = 1;
        $options->{default}  = sub {
            confess "Attribute $name must be provided before calling reader";
        };
    }
};

sub apply_to_result_source { }

1;

__END__

=head1 INTERNAL METHODS

=head2 _process_options

Attributes that are lazy and do not have a builder or default set become lazy and
a default assigned, that dies when called. This enables result classes to have
incomplete data.

=head1 ROLES

Does role L<MooseX::Attribute::LazyInflator::Meta::Role::Attribute>.
