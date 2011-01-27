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

sub apply_to_result_source {}

1;
