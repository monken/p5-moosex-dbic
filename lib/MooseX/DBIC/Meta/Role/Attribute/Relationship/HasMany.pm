package MooseX::DBIC::Meta::Role::Attribute::Relationship::HasMany;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Attribute::Relationship';

use MooseX::DBIC::Types q(:all);
use Moose::Util::TypeConstraints qw();

sub _build_foreign_key {
    my $self = shift;
    Class::MOP::load_class($self->related_class);
    return $self->related_class->meta->get_attribute($self->associated_class->name->table_name);
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
            accessor => 'multi',
            join_type => 'LEFT',
            cascade_delete => 1,
            cascade_copy => 1,
        }
    );
};

sub _build_related_class {
    shift->type_constraint->type_parameter->class
}

sub reverse_relationship {
    shift->foreign_key;
}

sub build_options {
    my ($class, $for, $name, %options) = @_;
    if($options{foreign_key}) {
        my $isa = Moose::Util::TypeConstraints::find_or_parse_type_constraint($options{isa});
        Class::MOP::load_class($isa->type_parameter->class);
        $options{foreign_key} = $isa->type_parameter->class->meta->get_attribute($options{foreign_key}); 
    }
    return ( 
        is => 'rw',
        %options,
        lazy => 1,
        default => sub { my $self = shift; return $self->_build_related_resultset($self->meta->get_attribute($name)); } 
    );
}

1;