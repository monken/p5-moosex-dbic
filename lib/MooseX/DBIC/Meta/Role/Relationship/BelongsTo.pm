package MooseX::DBIC::Meta::Role::Relationship::BelongsTo;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Relationship' => { -alias    => { is_dirty => 'relationship_is_dirty' } };
with 'MooseX::DBIC::Meta::Role::Column' => { -alias    => { is_dirty => 'column_is_dirty' } };

use MooseX::DBIC::Types q(:all);
use List::Util qw(first);
use MooseX::DBIC::Util ();

sub _build_foreign_key {
    shift
}
sub _build_join_condition {
    my $self = shift;
    my $fk = $self->foreign_key;
    my $pk = $self->related_class->meta->get_primary_key;
    Moose->throw_error(q(Couldn't find primary key for class ), 
                       $self->related_class, 
                       qq(. Please add a join_condition to ),
                       $self->name, q( in class ), $self->associated_class->name )
        unless($pk);
    return { 'foreign.' . $pk->name => 'self.' . $fk->name };
} 

after apply_to_result_source => sub {
    my ($self, $result) = @_;
    $result->add_relationship(
        $self->name, 
        $self->related_class, 
        $self->join_condition, 
        {join_type => $self->join_type}
    );
};

sub _build_join_type {
    shift->is_required ? '' : 'LEFT';
}

sub reverse_relationship {
    my $self = shift;
    return first { $_->foreign_key eq $self } $self->related_class->meta->get_all_relationships;
}

sub is_dirty {
    my ($attr, $self) = @_;
    return $attr->column_is_dirty($self) || $attr->relationship_is_dirty($self);
}

around _process_options => sub {
    my ($orig, $self, $name, $options) = @_;
    $self->$orig($name, $options);
    $options->{type_constraint} = Result[$options->{type_constraint}]
        unless($options->{type_constraint}->parent eq Result);
};

1;