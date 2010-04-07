package MooseX::DBIC::Meta::Role::Class;

use Moose::Role;
use MooseX::ClassAttribute;
use MooseX::DBIC::Types q(:all);
use List::Util qw(first);



sub get_column_list {
    my $self = shift;
    return grep {
        $self->get_attribute($_)
          ->does('MooseX::DBIC::Meta::Role::Attribute::Column')
    } $self->get_attribute_list;
}

sub get_relationship_list {
    my $self = shift;
    return grep {
        $self->get_attribute($_)
          ->does('MooseX::DBIC::Meta::Role::Attribute::Relationship')
    } $self->get_attribute_list;
}

sub get_all_columns {
    my $self = shift;
    return grep { $_->does('MooseX::DBIC::Meta::Role::Attribute::Column') } $self->get_all_attributes;
}

sub get_all_relationships {
    my $self = shift;
    return grep { $_->does('MooseX::DBIC::Meta::Role::Attribute::Relationship') } $self->get_all_attributes;
}

sub get_relationship {
    my ($self, $rel) = @_;
    return $self->get_attribute($rel) if(first { $_ eq $rel } $self->get_relationship_list);
}


sub find_relationship_by_name {
    my ($self, $rel) = @_;
    return first { $_->name eq $rel } $self->get_all_relationships;
}

sub add_relationship {
    my ($self, $name, %options) = @_;
    my $role = 'MooseX::DBIC::Meta::Role::Attribute::Relationship::' . $options{type};
    $options{traits} ||= [];
    push(@{$options{traits}}, 
        qw(MooseX::DBIC::Meta::Role::Attribute
           MooseX::Attribute::Deflator::Meta::Role::Attribute), $role);

    my $metaclass = $self->attribute_metaclass->interpolate_class(
        { traits => $options{traits} }
    );
    
    my $attrs = ref $name eq 'ARRAY' ? $name : [$name];
    foreach my $attr ( @{$attrs} ) {
        %options = $metaclass->build_options($self, $attr, %options);
        $self->add_attribute( $metaclass->new( $attr => %options ) );
    }
}

1;
