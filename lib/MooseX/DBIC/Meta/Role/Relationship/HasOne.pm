package MooseX::DBIC::Meta::Role::Relationship::HasOne;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Relationship::MightHave';

around _process_options => sub {
    my ($orig, $self, $name, $options) = @_;
    $self->$orig($name, $options);
    $options->{required} = 1;
};

1;