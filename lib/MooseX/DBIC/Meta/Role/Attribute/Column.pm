package MooseX::DBIC::Meta::Role::Attribute::Column;

use Moose::Role;

has 
    column_info => ( is => 'rw', isa => 'HashRef' ); # merging hashref?

1;