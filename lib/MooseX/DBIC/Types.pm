package MooseX::DBIC::Types;

use MooseX::Types -declare => [qw(Relationship Result ResultSet JoinType)];
use MooseX::Types::Moose qw(HashRef Object);
use MooseX::Attribute::Deflator;
use Moose::Util::TypeConstraints;
use MooseX::DBIC::ResultProxy;

my $REGISTRY = Moose::Util::TypeConstraints->get_type_constraint_registry;

enum Relationship,
    qw(HasOne HasMany BelongsTo ManyToMany HasSuperclass MightHave);

enum JoinType,
    qw(LEFT RIGHT INNER), '';

subtype Result,
    as Object;

deflate ResultSet.'[]', via { foreach my $row(@{$_->get_cache || []}) { $row->update_or_insert } };

    
deflate Result, via { 
    $_->update_or_insert; 
    $_->id;
};
inflate Result, via { 
    my ($result, $constraint, $inflate, $rs, $attr) = @_; 
    my $id = $_;
    my $class = $attr->proxy_class->name;
    return $class->new( id => $id, '-result_source' => $rs->schema->source($attr->related_class->dbic_result_class) );
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