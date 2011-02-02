package MooseX::DBIC::Meta::Role::Class;

#use base 'DBIx::Class::ResultSource::Table';

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
has column_list => ( is => 'rw', default => sub {[]} );
has relationship_list => ( is => 'rw', default => sub {[]} );
has relationships => ( is => 'rw', default => sub {[]} );
has resultset_class => ( is => 'rw', isa => 'Str', lazy_build => 1 );
has result_class => ( is => 'rw', isa => 'Str', lazy_build => 1 );

sub _build_resultset_class {
    my $meta = shift;
    my $resultset = $meta->name . '::Set';
    eval {
        Class::MOP::load_class($resultset);
    } and return $resultset or return 'MooseX::DBIC::Set';
}

sub _build_result_class { shift->name }

sub from { shift->name->table_name }

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
    my %options = ( is => 'rw', isa => 'Str', @_ );

    $options{traits} ||= [];
    push( @{ $options{traits} }, qw(MooseX::DBIC::Meta::Role::Column) );

    my $attrs = ref $name eq 'ARRAY' ? $name : [$name];

    foreach my $attr ( @{$attrs} ) {
        $meta->add_attribute( $attr => %options );
        $meta->column_list( [ @{ $meta->column_list }, $attr ] );
    }
}

sub remove_column {
    my ($self, $column) = @_;
    $self->column_list([grep { $_ ne $column } @{$self->column_list}]);
    $self->remove_attribute($column);
}

sub get_column {
    my ($self, $name) = @_;
    $name = first { $_ eq $name } $self->get_column_list;
    return unless($name);
    return $self->orig_class->get_attribute( $name );
}

sub has_column {
    my ($self, $name) = @_;
    first { $_ eq $name } $self->get_column_list;
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

*get_all_relationships = \&get_relationships;

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

    
    my $attrs = ref $name eq 'ARRAY' ? $name : [$name];
    foreach my $attr ( @{$attrs} ) {
        $self->relationship_list([@{$self->relationship_list}, $attr]);
        my $rel = $self->add_attribute($attr => %options, associated_class => $self->name );
        next if($rel->isa('Moose::Meta::Role::Attribute'));
        $self->relationships([@{$self->relationships}, $rel]);
        $self->column_list([@{$self->column_list}, $attr])
            if($rel->does('MooseX::DBIC::Meta::Role::Column'));
        
    }
}

sub set_columns {
    my ($meta, $object, $values) = @_;
    map { $meta->set_column($object, $_, $values->{$_}) } keys %$values;
}

sub set_column {
    my ($meta, $object, $col, $val) = @_;
    $col = $meta->get_column($col);
    return unless($col);
    if(defined $val) {
        $col->set_value($object, $val);
    } else {
        $col->clear_value($object);
    }
}

1;

__END__

=head1 METHODS

=head2 from

Returns the table name.



=head1 ATTRIBUTES

=head2 column_list

Contains the column names.

=head2 relationship_list

Contains the relationship names.

=head2 relationship

Contains the relationship meta classes.

=head2 result_class

The result class. Defaults to the name of the class.

=head2 resultset_class

Name of the resultset class. If a class exists, that has C<::Set> appended 
to the L</result_class> name, it is used (e.g. a class MySchema::User will
have MyApp::User::Set as resultset class, if it exists). Otherwise 
L<MooseX::DBIC::Set> is used as resultset class.

=head2 get_all_columns

Filters L<Moose::Meta::Class/get_all_attributes> for attributes with the
L<MooseX::DBIC::Meta::Role::Column> role applied.

B<< Note: This returns all columns in the inheritance hierarchy. This is probably not what you want.
See L</get_column_list> instead. >>

=head2 get_all_relationships

Filters L<Moose::Meta::Class/get_all_attributes> for attributes with the
L<MooseX::DBIC::Meta::Role::Column> role applied.

B<< Note: This returns all columns in the inheritance hierarchy. This is probably not what you want.
See L</get_relationship_list> instead. >>

=head1 INTERNAL ATTRIBUTES

=head2 orig_class

This attribute contains the name of the original class. L<DBIx::Class::Schema/compose_namespace>
creates a subclass of each result class and gives it a new name. To have methods like
L</get_attribute> still working, we need to call them on the original class since the subclass
will have no direct attributes.

=head1 INTERNAL METHODS

=head2 get_orig_class

Builder for L</orig_class>.