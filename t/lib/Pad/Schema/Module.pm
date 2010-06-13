package Pad::Schema::Module;

use MooseX::DBIC;
use List::MoreUtils qw(uniq);


has_column name => ( required => 1 );
has_column 'version';
belongs_to 'release';
belongs_to file => ( isa => 'Pad::Schema::File' );

__PACKAGE__->meta->make_immutable;