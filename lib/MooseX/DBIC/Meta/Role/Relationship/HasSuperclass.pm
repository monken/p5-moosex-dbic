package MooseX::DBIC::Meta::Role::Relationship::HasSuperclass;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Relationship::BelongsTo';

use MooseX::DBIC::Types q(:all);

around build_options => sub {
    my ($orig, $self, $for, $name, %options) = @_;
    %options = $self->$orig($for, $name, %options);
    my $related_result = $options{related_class};
    my @handles = map { $for->remove_attribute($_->name); $_->name } 
                  grep { !$for->has_attribute($_->name) } 
                    $related_result->meta->get_all_columns;
    return %options, required => 1, handles => \@handles;
};

1;