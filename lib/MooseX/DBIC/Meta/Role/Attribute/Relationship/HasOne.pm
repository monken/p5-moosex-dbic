package MooseX::DBIC::Meta::Role::Attribute::Relationship::HasOne;

use Moose::Role;
with 'MooseX::DBIC::Meta::Role::Attribute::Relationship::MightHave';

has '+join_type' => ( default => 'LEFT' );


1;