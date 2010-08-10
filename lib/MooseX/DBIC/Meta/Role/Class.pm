package MooseX::DBIC::Meta::Role::Class;

use Moose::Role;
use MooseX::DBIC::Types q(:all);
use List::Util qw(first);
use List::MoreUtils ();

my $application_to_class_class = Moose::Meta::Class->create_anon_class( 
    superclasses => ['Moose::Meta::Role::Application::ToClass'], 
    cache => 1 );
$application_to_class_class->add_after_method_modifier(apply_attributes => sub {
    my ($self , $role, $class) = @_;
    my $attr_metaclass = $class->attribute_metaclass;
    foreach my $attribute_name ( $role->get_class_attribute_list() ) {
        next if ( $class->has_class_attribute($attribute_name)
            && $class->get_class_attribute($attribute_name)
            != $role->get_class_attribute($attribute_name) );

        $class->add_class_attribute(
            $role->get_class_attribute($attribute_name)
                ->attribute_for_class($attr_metaclass) );
    }
});

sub application_to_class_class { 
    return $application_to_class_class->name;
}

has orig_class => ( is => 'ro', lazy => 1, builder => 'get_orig_class' );
has column_list => ( is => 'rw', default => sub {['id']} ); # TODO: Role applicator
has relationship_list => ( is => 'rw', default => sub {[]} );
has relationships => ( is => 'rw', default => sub {[]} );

sub get_orig_class {
    my $class = first { first { $_->name eq 'MooseX::DBIC::Role::Result' } @{$_->meta->roles} } shift->class_precedence_list;
    return $class->meta;
}

sub get_all_columns {
    my $self = shift;
    return grep { $_->does('MooseX::DBIC::Meta::Role::Column') } $self->orig_class->get_all_attributes;
}

sub add_column {
  my $meta    = shift;
  my $name    = shift;
  my %options = (is => 'rw', isa => 'Str', @_);
  $options{lazy_required} = 1 if($options{required} && !$options{lazy_build} && !$options{builder});
  $options{traits} ||= [];
  push(@{$options{traits}}, qw(MooseX::DBIC::Meta::Role::Column));
  
  my $attrs = ref $name eq 'ARRAY' ? $name : [$name];
  
  foreach my $attr ( @{$attrs} ) {
      $meta->add_attribute( $attr => %options );
      $meta->column_list([@{$meta->column_list}, $attr]);
  }
}

sub remove_column {
    my ($self, $column) = @_;
    $self->column_list([grep { $_ ne $column } @{$self->column_list}]);
    $self->remove_attribute($column);
}

sub get_column {
    my ($self, $name) = @_;
    return $self->find_attribute_by_name( 
        first { $_ eq $name } $self->get_column_list
    );
}

sub get_column_list {
    return @{shift->orig_class->column_list};
}

sub get_dirty_column_list {
    my ($meta, $self) = @_;
    $self->{_dirty_in_progress} ? return () : ($self->{_dirty_in_progress} = 1);
    my @cols = grep { !$self->in_storage || $meta->get_column($_)->is_dirty($self) } $meta->get_column_list;
    delete $self->{_dirty_in_progress};
    return @cols;
}

sub is_dirty {
    return shift->get_dirty_column_list(shift);
}

sub get_primary_key {
    my $self = shift;
    return first { $_->primary_key } map { $self->get_column($_) } $self->get_column_list;
}

sub get_relationship_list {
    return @{shift->orig_class->relationship_list};
}

sub get_relationships {
    return @{shift->orig_class->relationships};
}

sub get_all_relationships {
    my $self = shift;
    return grep { $_->does('MooseX::DBIC::Meta::Role::Relationship') } $self->get_all_attributes;
}

sub get_relationship {
    my ($self, $rel) = @_;
    return $self->orig_class->get_attribute($rel) if(first { $_ eq $rel } $self->get_relationship_list);
}


sub find_relationship_by_name {
    my ($self, $rel) = @_;
    return first { $_->name eq $rel } $self->get_all_relationships;
}

sub add_relationship {
    my ($self, $name, %options) = @_;
    my $role = 'MooseX::DBIC::Meta::Role::Relationship::' . $options{type};
    $options{traits} ||= [];
    push(@{$options{traits}}, $role, 'MooseX::Attribute::Deflator::Meta::Role::Attribute');

    my $metaclass = $self->attribute_metaclass->interpolate_class(
        { traits => $options{traits} }
    );
    
    my $attrs = ref $name eq 'ARRAY' ? $name : [$name];
    foreach my $attr ( @{$attrs} ) {
        #my %copy = $metaclass->build_options($self, $attr, %options);
        $self->relationship_list([@{$self->relationship_list}, $attr]);
        my $rel = $self->add_attribute( $metaclass->new( $attr => %options, associated_class => $self->name ) );
        $self->relationships([@{$self->relationships}, $rel]);
        $self->column_list([@{$self->column_list}, $attr])
            if($rel->does('MooseX::DBIC::Meta::Role::Column'));
        
    }
}

1;
