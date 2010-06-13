package MooseX::DBIC::Meta::Role::Relationship::HasMany;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Relationship::MightHave';

use MooseX::DBIC::Types q(:all);
use Moose::Util::TypeConstraints qw();
use List::Util ();
use Lingua::EN::Inflect ();

has dbic_accessor => ( is => 'ro', default => 'multi' );

around _process_options => sub {
    my ($orig, $self, $name, $options) = @_;
    $self->$orig($name, $options);
    $options->{type_constraint} = ResultSet[$options->{type_constraint}]
        unless($options->{type_constraint}->parent eq ResultSet);
};

sub _build_builder {
    my ($s, $name) = @_;
    return sub {
        my $self = shift;
        $self->_build_related_resultset($self->meta->get_relationship($name));
    }
}

sub _build_related_class {
    my $self = shift;
    my ($name, $associated_class) = ref $self ? ($self->name, $self->associated_class->name) : @_;
    (my $singular = $name) =~ s/s$//;
    Moose->throw_error('Couldn\'t guess related class for relationship ', $name, ' in class ', 
        ref $self ? ref $self : $self, '. Please specify explicitly (e.g. ( isa => \'MyClass\' ).')
        unless(Lingua::EN::Inflect::PL_eq($singular, $name));
    return MooseX::DBIC::Util::find_related_class($singular, $associated_class);
}

sub is_dirty {
    my ($attr, $self) = @_;
    return 0 unless($attr->has_value($self));
    my $rows = $attr->get_value($self)->get_cache;
    List::Util::first { $_ && $_->meta->is_dirty($_) } @$rows;
}

1;