package MooseX::DBIC::Types;

use MooseX::Types -declare => [qw(Relationship Result ResultSet)];
use MooseX::Types::Moose qw(HashRef Object);
use MooseX::Attribute::Deflator;
use Moose::Util::TypeConstraints;

my $REGISTRY = Moose::Util::TypeConstraints->get_type_constraint_registry;

enum Relationship,
    qw(HasOne HasMany BelongsTo ManyToMany);

subtype Result,
    as Object;

deflate Result, via { $_->insert_or_update; $_->id };
inflate Result, via { 
    my ($result, $constraint, $inflate, $rs, $attr) = @_; 
    $rs->schema->resultset($attr->related_source)->find($_);
};

$REGISTRY->add_type_constraint(
    Moose::Meta::TypeConstraint::Parameterizable->new(
        name               => 'MooseX::DBIC::Types::ResultSet',
        package_defined_in => __PACKAGE__,
        parent             => find_type_constraint('Object'),
        constraint         => sub { $_->isa('DBIx::Class::ResultSet') },
        constraint_generator => sub {
            my $type_parameter = shift;
            my $check          = $type_parameter->_compiled_type_constraint;
            return sub { 1; }
        }
    )
);

Moose::Util::TypeConstraints::add_parameterizable_type($REGISTRY->get_type_constraint('MooseX::DBIC::Types::ResultSet'));


1;