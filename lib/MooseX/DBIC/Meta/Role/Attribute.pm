package MooseX::DBIC::Meta::Role::Attribute;

use Moose::Role;

with 'MooseX::Attribute::LazyInflator::Meta::Role::Attribute';

sub apply_to_result_source {}


1;