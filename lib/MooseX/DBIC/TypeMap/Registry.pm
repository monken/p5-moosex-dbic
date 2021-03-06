package MooseX::DBIC::TypeMap::Registry;
# ABSTRACT: Registry class for type mapping
use Moose;
use Moose::Util::TypeConstraints ();

has map => ( 
	traits => ['Hash'],
	is => 'rw', 
	isa => 'HashRef[Str]', 
	default    => sub { {} },
    handles    => { 
		has => 'get', 
		get => 'get', 
		set => 'set',
		add => 'set'
	}
);

sub find {
    my ($self, $type) = @_;
    my $constraint = $self->get($type);
    return defined $constraint 
        ? $constraint 
        : $self->find(Moose::Util::TypeConstraints::find_or_create_isa_type_constraint($type)->parent->name);
}

1;
__END__
=head1 DESCRIPTION

This class contains a registry for mapping Moose types to SQL data types.

=head1 ATTRIBUTES

=over 4

=item B<< map ( isa => HashRef[Str] ) >>

=back

=head1 METHODS

=over 4

=item B<< has( $type_constraint, $str ) >>

=item B<< get( $type_constraint, $str ) >>

=item B<< set( $type_constraint, $str ) >>

=item B<< add( $type_constraint, $str ) >>

Does what you would expect.

=item B<< find( $type_constraint, $str ) >>

Bubbles up the type hierarchy to find a map.

=back