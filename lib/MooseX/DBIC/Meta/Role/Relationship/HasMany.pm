package MooseX::DBIC::Meta::Role::Relationship::HasMany;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Relationship';

use MooseX::DBIC::Types q(:all);
use Moose::Util::TypeConstraints qw();
use List::Util ();

sub _build_foreign_key {
    my $self = shift;
    Class::MOP::load_class($self->related_class);
    return $self->related_class->meta->get_attribute($self->associated_class->name->table_name);
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
            accessor => 'multi',
            join_type => 'LEFT',
            cascade_delete => $self->cascade_delete,
            cascade_copy => $self->cascade_update,
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

sub is_dirty {
    my ($attr, $self) = @_;
    return 0 unless($attr->has_value($self));
    my $rows = $attr->get_value($self)->get_cache;
    List::Util::first { $_ && $_->meta->is_dirty($_) } @$rows;
}

1;