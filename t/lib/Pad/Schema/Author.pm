package Pad::Schema::Author;

use MooseX::DBIC;

has_column name        => ( required => 1 );
has_many releases => ( isa => ResultSet['Pad::Schema::Release'] );

__PACKAGE__->meta->make_immutable;