package MooseX::DBIC::Meta::Role::Method::Accessor;

# ABSTRACT: Lazy inflate attributes
use base 'MooseX::Attribute::LazyInflator::Meta::Role::Method::Accessor';
use strict;
use warnings;
use Carp qw(confess);

sub _inline_check_lazy {
    my ($self, $instance) = @_;
    my $slot_exists = $self->_inline_has($instance);
    my $code = "if(!$slot_exists && !\$attr->is_loaded($instance)) {\n";
    $code .= $self->_inline_store($instance, "\$attr->load_from_storage($instance)");
    $code .= "delete ${instance}->{dirty_columns}->{\$attr->name};\n";
    $code .= "}\n\n";
    $code .= $self->next::method($instance);
    return $code;
}

sub _generate_clearer_method_inline {
    my $self          = shift;
    my $attr          = $self->associated_attribute;
    my $attr_name     = $attr->name;
    my $meta_instance = $attr->associated_class->instance_metaclass;

    my ( $code, $e ) = $self->_eval_closure(
        {},
        'sub {'
        . $meta_instance->inline_deinitialize_slot('$_[0]', $attr_name) . ';'
        . $meta_instance->inline_mark_dirty('$_[0]', $attr_name)
        . '}'
    );
    confess "Could not generate inline clearer because : $e" if $e;

    return $code;
}

1;