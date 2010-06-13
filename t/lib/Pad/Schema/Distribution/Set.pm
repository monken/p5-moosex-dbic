package Pad::Schema::Distribution::Set;
use Moose;
extends 'DBIx::Class::ResultSet';

sub find_by_name {
    return shift->search({ name => shift })->first;
}

1;