package MooseX::DBIC::Meta::Role::Attribute::Relationship::HasOne;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Attribute::Relationship::MightHave';

around build_options => sub {
    my ($orig, $self, $for, $name, %options) = @_;
    %options = $self->$orig($for, $name, %options);
    return %options, required => 1;
};

1;