package MooseX::DBIC::Meta::Role::Attribute;

use Moose::Role;

has 
    column_info => ( is => 'rw', isa => 'HashRef' );

1;