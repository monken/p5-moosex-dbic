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

sub get_relationship {
    my ($self, $rel) = @_;
    return map { $self->get_attribute($_) } first { $_ eq $rel } $self->get_relationship_list;
}


sub find_relationship_by_name {
    my ($self, $rel) = @_;
    return first { $_->name eq $rel } $self->get_all_relationships;
}

sub add_relationship {
    my ($self, $name, %options) = @_;
    $options{traits} ||= [];
    push(@{$options{traits}}, 
        qw(MooseX::DBIC::Meta::Role::Attribute 
           MooseX::DBIC::Meta::Role::Attribute::Relationship
           MooseX::Attribute::Deflator::Meta::Role::Attribute));

    if($options{type} eq 'HasSuperclass') {
        my $related_result = $options{isa};
        my @handles = map { $self->remove_attribute($_->name); $_->name } 
                      grep { !$self->has_attribute($_->name) } 
                        $related_result->meta->get_all_columns;
        %options = 
              ( is             => 'rw',
                %options,
                isa            => Result,
                related_class  => $related_result,
                required       => 1,
                lazy           => 1,
                handles => \@handles,
                default        => sub { my $self = shift; return $self->_build_relationship($self->meta->get_attribute($name)); }
        );
        push(@{$options{traits}}, qw(MooseX::DBIC::Meta::Role::Attribute::Column));
    } elsif($options{type} eq 'BelongsTo') {
    
        my $related_result = $options{isa};
        %options = 
              ( is             => 'rw',
                %options,
                isa            => Result,
                related_class  => $related_result,
                lazy           => 1,
                default        => sub { my $self = shift; return $self->_build_relationship($self->meta->get_attribute($name)); }
        );
        push(@{$options{traits}}, qw(MooseX::DBIC::Meta::Role::Attribute::Column));
    } elsif($options{type} eq 'HasMany') {
        %options = ( 
            is => 'rw',
            %options,            
            type => 'HasMany', 
            lazy => 1,
            default => sub { my $self = shift; return $self->_build_related_resultset($self->meta->get_attribute($name)); } 
        );
    } else { die }
    
    my $attrs = ref $name eq 'ARRAY' ? $name : [$name];
    foreach my $attr ( @{$attrs} ) {
        $self->add_attribute( $attr => %options );
    }
}

1;
