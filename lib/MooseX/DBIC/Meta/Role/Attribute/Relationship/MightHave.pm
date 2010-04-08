package MooseX::DBIC::Meta::Role::Attribute::Relationship::MightHave;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Attribute::Relationship';

use MooseX::DBIC::Types q(:all);

sub _build_foreign_key {
    my $self = shift;
    return $self->related_class->meta->get_attribute($self->associated_class->name->table);
};

sub _build_join_condition {
    my $self = shift;
    my $fk = $self->foreign_key;
    return { 'foreign.'.$fk->name => 'self.id' };
} 

after apply_to_result_source => sub {
    my ($self, $result) = @_;
    $result->add_relationship(
        $self->name, 
        $self->related_class, 
        $self->join_condition, 
        {
            accessor => 'single',
            join_type => $self->join_type,
            cascade_delete => 1,
            cascade_copy => 1,
        }
    );
};

sub _build_related_class {
    shift->type_constraint->class
}

sub reverse_relationship {
    shift->foreign_key;
}

sub _build_join_type { 'LEFT' }

sub build_options {
    my ($class, $for, $name, %options) = @_;
    $options{foreign_key} = $options{isa}->meta->get_attribute($options{foreign_key}) if($options{foreign_key});    
     return (
            is => 'rw',
            %options,
            isa => Result,
            related_class => $options{isa},
            lazy => 1,
            default => sub { my $self = shift; return $self->_build_relationship($self->meta->get_attribute($name)); } 
    );
}

1;