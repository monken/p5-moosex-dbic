package Pad::Schema::Module::Set;
use Moose;
extends 'DBIx::Class::ResultSet';

sub find_latest_by_name {
    my ($self, $name) = @_;
    return $self->search(
        { name => $name }, 
        { 
            join => 'release', 
            order_by => { -desc => 'release.version_numified'}
        }
    )->first;
}

1;