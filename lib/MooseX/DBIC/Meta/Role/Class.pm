package MooseX::DBIC::Meta::Role::Class;

use Moose::Role;
use MooseX::ClassAttribute;
use MooseX::DBIC::Types q(:all);

class_has column_attribute_metaclass =>
  ( is => 'rw', isa => 'Str', lazy_build => 1 );

class_has relationship_attribute_metaclass =>
  ( is => 'rw', isa => 'Str', lazy_build => 1 );

sub _build_column_attribute_metaclass {

    return Moose::Meta::Class->create_anon_class(
        superclasses => ['Moose::Meta::Attribute'],
        roles        => [ qw(MooseX::DBIC::Meta::Role::Attribute MooseX::DBIC::Meta::Role::Attribute::Column MooseX::Attribute::Deflator::Meta::Role::Attribute) ],
        cache        => 1,
    )->name;
}

sub _build_relationship_attribute_metaclass {

    return Moose::Meta::Class->create_anon_class(
        superclasses => ['Moose::Meta::Attribute'],
        roles => [ qw(MooseX::DBIC::Meta::Role::Attribute MooseX::DBIC::Meta::Role::Attribute::Column MooseX::DBIC::Meta::Role::Attribute::Relationship MooseX::Attribute::Deflator::Meta::Role::Attribute) ],
        cache => 1,
    )->name;
}

sub get_column_attribute_list {
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

sub add_relationship {
    my ($self, $name, %options) = @_;
    if($options{type} eq 'BelongsTo') {
        my $related_result = $options{isa};
        my @handles = map { $self->remove_attribute($_->name); $_->name } 
                      grep { !$self->has_attribute($_->name) } 
                        $related_result->meta->get_all_columns;
        
        my $rel = $self->relationship_attribute_metaclass->new(
            $name => (
                is             => 'rw',
                isa            => Result,
                type           => 'BelongsTo',
                related_class  => $related_result,
                required       => 1,
                lazy           => 1,
                handles => \@handles,
                default        => sub { my $self = shift; return $self->_build_relationship($self->meta->get_attribute($name)); }
            )
        );
        $self->add_attribute($rel);
    }
}

1;
