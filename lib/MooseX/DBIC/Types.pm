package MooseX::DBIC::Types;

use MooseX::Types -declare => [qw(Relationship Result ResultSet JoinType)];
use MooseX::Types::Moose qw(HashRef Object Str);
use MooseX::Attribute::Deflator 1.101600;
use Moose::Util::TypeConstraints;
use MooseX::DBIC::ResultProxy;
use strict;
use warnings;

my $REGISTRY = Moose::Util::TypeConstraints->get_type_constraint_registry;

enum Relationship,
    qw(HasOne HasMany BelongsTo ManyToMany HasSuperclass MightHave);

enum JoinType,
    qw(LEFT RIGHT INNER left right inner), '';

inflate ResultSet.'[]', via {
    my ($attr, $constraint, undef, $obj) = @_;
    my $value = $_;
    my $rs = $obj->result_source;
    my $related_class = $attr->related_class;
    $value = [ $value ] if( ref $value eq 'HASH' );
    my $resultset = $value;
    if(ref $value eq 'ARRAY') {
        $resultset = $rs->schema->resultset($attr->related_class);
        my @rows =  map { ref $_ eq 'HASH' ? $resultset->new_result($_) : $_ } @$value;
        $resultset->set_cache(\@rows);
    } elsif(!$resultset->isa('DBIx::Class::ResultSet')) {
        Moose->throw_error('Cannot inflate from ', ref $value);
    }
    my $fk = $attr->foreign_key;
    my $rows = $resultset->get_cache;
    foreach my $row (@$rows) {
        $fk->set_raw_value($row, $obj);
        $fk->_weaken_value($row);
        $row->_inflated_attributes->{$fk->name}++;
    }
    return $resultset;
};
    
deflate ResultSet.'[]', via { foreach my $row(@{$_->get_cache || []}) { $row->update_or_insert } };

deflate Result.'[]', via {
    $_->update_or_insert unless($_->does('MooseX::DBIC::Meta::Role::ResultProxy'));
    my $pk = $_->meta->get_primary_key->name;
    $_->$pk;
};


inflate Result.'[]', via {
    my ($attr, $constraint, undef, $obj) = @_;
    my $value = $_;
    my $rs = $obj->result_source;
    my $related_class = $attr->related_class;
    if(ref $value eq 'HASH') {
        $value = $rs->schema->resultset($related_class)->new_result($value);
    } elsif(!ref $value) {
        my $class = $attr->proxy_class->name;
        $value = $class->new( $attr->related_class->meta->get_primary_key->name => $value, '-result_source' => $rs->schema->source($attr->related_class) );
    } elsif(ref $value ne $related_class) {
        $attr->throw_error('Cannot inflate from ', ref $value);
    }
    my $fk = $attr->foreign_key;
    $fk->set_raw_value($value, $obj);
    $fk->_weaken_value($value);
    $value->_inflated_attributes->{$fk->name}++;
    return $value;
    
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


$REGISTRY->add_type_constraint(
    Moose::Meta::TypeConstraint::Parameterizable->new(
        name               => Result,
        package_defined_in => __PACKAGE__,
        parent             => find_type_constraint('Object'),
        constraint         => sub { $_->does('MooseX::DBIC::Role::Result') },
        constraint_generator => sub {
            my $type_parameter = shift;
            my $check          = $type_parameter->_compiled_type_constraint;
            return sub { 1; }
        }
    )
);

Moose::Util::TypeConstraints::add_parameterizable_type($REGISTRY->get_type_constraint(Result));


1;