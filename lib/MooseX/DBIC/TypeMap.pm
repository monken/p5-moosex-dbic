package MooseX::DBIC::TypeMap;

use strict;
use warnings;
use Moose::Exporter;
use MooseX::DBIC::TypeMap::Registry;

Moose::Exporter->setup_import_methods(
    as_is => [
        qw( map_type )
    ],
);

my $REGISTRY = MooseX::DBIC::TypeMap::Registry->new;

sub get_registry { $REGISTRY }

sub map_type ($$) {
    $REGISTRY->set(shift, shift);
}

1;