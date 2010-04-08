package MooseX::DBIC::Meta::Role::Attribute::Column;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Attribute';


has column_info => ( is => 'rw', isa => 'HashRef' ); # merging hashref?

after apply_to_result_source => sub {
    my ($self, $result) = @_;
    
    $result->add_columns(
        $self->name => {
            is_nullable => !$self->is_required,
            %{ $self->column_info || {} }
        });
};

1;