package Pad::Schema::File;

use MooseX::DBIC;
use File::stat ();

has_column name   => ( required => 1 );
has_column binary => ( isa => 'Bool', required => 1, default => 0 );
has_column content => ( isa => 'ScalarRef[Str]', required => 1 );
has_column stat => ( isa => 'File::stat', required => 1, handles => [qw(size)] );

belongs_to 'release';
might_have module => ( isa => 'Pad::Schema::Module', predicate => 'has_module' );


__PACKAGE__->meta->make_immutable;

__END__

=head1 TODO

=over 4

=item B<Enable TOAST on content column>

=item B<Full-text index only on non binary files>

=back