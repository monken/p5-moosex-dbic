package Pad::Schema::Release;

use MooseX::Attribute::LazyInflator;
use MooseX::DBIC;

has_column uploaded   => ( isa => 'DateTime', required => 1, traits => [qw(LazyInflator)] );
has_many dependencies => ( isa => ResultSet['Pad::Schema::Dependency'] );
has_many files        => ( isa => ResultSet['Pad::Schema::File'] );
has_many modules      => ( isa => ResultSet['Pad::Schema::Module'] );
has_column resources => ( isa => 'HashRef' );
belongs_to author => ( required => 1 );
belongs_to distribution => ( required => 1 );

__PACKAGE__->meta->make_immutable;

__END__

=head1 SEE ALSO

L<http://search.cpan.org/perldoc?CPAN::Meta::Spec>  