package MooseX::DBIC::Meta::Role::Attribute::Column;

use Moose::Role;

has column_info => ( is => 'rw', isa => 'HashRef' ); # merging hashref?

sub apply_to_dbic_result_class {
    my ($self, $result) = @_;
    
    $result->add_columns(
        $self->name => {
            is_nullable => !$self->is_required,
            %{ $self->column_info || {} }
        });
}

1;