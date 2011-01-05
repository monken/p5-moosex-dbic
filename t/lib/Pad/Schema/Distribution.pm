package Pad::Schema::Distribution;

use MooseX::DBIC;

has_column name       => ( required => 1 );
has_many releases => ( isa => ResultSet['Pad::Schema::Release'] );

__PACKAGE__->meta->make_immutable;

__END__

=head1 COLUMNS

=head2 name

Name of the distribution (e.g. Path-Class).

=head2 ratings

=head2 rating

The number of ratings and the final rating for this distribution.

=head2 pass

=head2 fail

=head2 na

=head2 unknown

CPAN::Testers results.

=head1 RELATIONSHIPS

=head2 releases

=head1 ATTRIBUTES

=head2 latest_release

Lazy attribute for L</get_latest_release>.

=head1 METHODS

=head2 get_latest_release

Gets the release of the distribution with the highest L<version_numified/Pad::Schema::Release>.

=head1 SEE ALSO

L<http://search.cpan.org/perldoc?CPAN::Meta::Spec>  