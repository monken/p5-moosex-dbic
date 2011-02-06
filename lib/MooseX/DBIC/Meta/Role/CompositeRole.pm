package MooseX::DBIC::Meta::Role::CompositeRole;

use strict;
use warnings;

use Moose::Util::MetaRole;
use Moose::Util qw(does_role);

use namespace::autoclean;
use Moose::Role;


sub _merge_class_attributes {
    my $self = shift; warn "FOOOO";
    # 
    # my @all_attributes;
    # foreach my $role (@{ $self->get_roles }) {
    #     if (does_role($role, 'MooseX::ClassAttribute::Trait::Role')) {
    #         push @all_attributes,
    #             map { $role->get_class_attribute($_) }
    #             $role->get_class_attribute_list;
    #     }
    # }
    # 
    # my %seen;
    # 
    # foreach my $attribute (@all_attributes) {
    #     my $name = $attribute->name;
    #     if (exists $seen{$name}) {
    #         next if $seen{$name} == $attribute;
    # 
    #         require Moose;
    #         Moose->throw_error( "Role '"
    #                 . $self->name()
    #                 . "' has encountered a class attribute conflict "
    #                 . "during composition. This is fatal error and cannot be disambiguated."
    #         );
    #     }
    #     $seen{$name} = $attribute;
    # }
    # foreach my $attribute (@all_attributes) {
    #     $self->add_class_attribute( $attribute->clone() );
    # }
    # 
    # return keys %seen;
}

around apply_params => sub {
    my ($orig, $self, @args) = @_; warn "FOOOO";
    # 
    # my $metarole = Moose::Util::MetaRole::apply_metaroles(
    #     for => $self->$orig(@args),
    #     role_metaroles => {
    #         application_to_class =>
    #             ['MooseX::ClassAttribute::Trait::Application::ToClass'],
    #         application_to_role =>
    #             ['MooseX::ClassAttribute::Trait::Application::ToRole'],
    #     },
    # );
    # $metarole->_merge_class_attributes;
    # return $metarole;
};

1;

# ABSTRACT: A trait that supports applying multiple roles at once

__END__

=pod

=head1 DESCRIPTION

This trait is used to allow the application of multiple roles (one
or more of which contain class attributes) to a class or role.

=head1 BUGS

See L<MooseX::ClassAttribute> for details.

=cut