package MooseX::DBIC::Meta::Role::Attribute::Relationship::HasSuperclass;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Attribute::Relationship::BelongsTo';

use MooseX::DBIC::Types q(:all);

1;