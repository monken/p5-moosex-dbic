package MooseX::DBIC::Meta::Role::Method::Accessor;

# ABSTRACT: Lazy inflate attributes
use base 'MooseX::Attribute::LazyInflator::Meta::Role::Method::Accessor';
use strict;
use warnings;

sub _inline_check_lazy {
    my ($self, $instance) = @_;
    my $slot_exists = $self->_inline_has($instance);
    my $code = "if(!$slot_exists && !\$attr->is_loaded($instance)) {\n";
    $code .= $self->_inline_store($instance, "\$attr->load_from_storage($instance)");
    $code .= "}\n\n";
    $code .= $self->next::method($instance);
    return $code;
}

1;