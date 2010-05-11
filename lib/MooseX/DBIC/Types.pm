package MooseX::DBIC::Types;

use MooseX::Types -declare => [qw(Relationship Result ResultSet JoinType)];
use MooseX::Types::Moose qw(HashRef Object);
use MooseX::Attribute::Deflator 1.100990;
use Moose::Util::TypeConstraints;
use MooseX::DBIC::ResultProxy;

my $REGISTRY = Moose::Util::TypeConstraints->get_type_constraint_registry;

enum Relationship,
    qw(HasOne HasMany BelongsTo ManyToMany HasSuperclass MightHave);

enum JoinType,
    qw(LEFT RIGHT INNER left right inner), '';

subtype Result,
    as Object;

deflate ResultSet.'[]', via { foreach my $row(@{$_->get_cache || []}) { $row->update_or_insert } };


deflate Result, via {
    $_->update_or_insert unless($_->does('MooseX::DBIC::Meta::Role::ResultProxy'));
    my $pk = $_->meta->get_primary_key->name;
    $_->$pk;
};
inflate Result, via {
    my ($result, $constraint, $inflate, $rs, $attr) = @_;
    my $id = $_;
    my $class = $attr->proxy_class->name;
    return $class->new( $attr->related_class->meta->get_primary_key->name => $id, '-result_source' => $rs->schema->source($attr->related_class) );
};

use MooseX::DBIC::TypeMap;

map_type 'Str', 'VARCHAR';
map_type 'Bool', 'BOOL';
map_type 'Int', 'INTEGER';
map_type 'Num', 'REAL';
map_type 'Any', '';
map_type Result, 'CHARACTER';

no MooseX::DBIC::TypeMap;



$REGISTRY->add_type_constraint(
    Moose::Meta::TypeConstraint::Parameterizable->new(
        name               => ResultSet,
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

Moose::Util::TypeConstraints::add_parameterizable_type($REGISTRY->get_type_constraint(ResultSet));


1;