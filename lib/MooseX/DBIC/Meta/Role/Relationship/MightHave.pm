package MooseX::DBIC::Meta::Role::Relationship::MightHave;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Relationship';

use MooseX::DBIC::Types q(:all);

has dbic_accessor => ( is => 'ro', default => 'single' );

sub _build_foreign_key {
    my $self = shift;
    return $self->related_class->meta->get_relationship($self->_foreign_key || $self->associated_class->name->table_name)
        || Moose->throw_error('Foreign key for relationship ', $self->name, ' could not be found. ',
           'Please specify explicitly in class ', $self->associated_class->name, '.');
};

sub _build_join_condition {
    my $self = shift;
    my $fk = $self->foreign_key;
    return { 'foreign.'.$fk->name => 'self.' . $self->associated_class->get_primary_key->name };
} 

after apply_to_result_source => sub {
    my ($self, $result) = @_;
    $result->add_relationship(
        $self->name, 
        $self->related_class, 
        $self->join_condition, 
        {
            accessor => $self->dbic_accessor,
            join_type => $self->join_type,
            cascade_delete => 1,
            cascade_copy => 1,
        }
    );
};

sub reverse_relationship {
    shift->foreign_key;
}

sub _build_join_type { 'LEFT' }

around _process_options => sub {
    my ($orig, $self, $name, $options) = @_;
    $self->$orig($name, $options);
    if(!ref $options->{foreign_key} && $options->{foreign_key}) {
        $options->{_foreign_key} = delete $options->{foreign_key};    
    }
    $options->{type_constraint} = Result[$options->{type_constraint}]
        unless($options->{type_constraint}->parent eq Result);
};

1;