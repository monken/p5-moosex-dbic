package Pad::Schema::Dependency;

use MooseX::DBIC;

has_column version => ( required => 1 );
has_column [qw(phase relationship)];
has_column module_name => ( required => 1 );
belongs_to release => ( required => 1 );


__PACKAGE__->meta->make_immutable;