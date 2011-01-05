package MooseX::DBIC::Meta::Role::Method::Constructor;
use strict;
use warnings;
use Moose::Role;

override _generate_BUILDARGS => sub {
    my ( $self, $class, $args ) = @_;
    my $meta = $self->associated_metaclass;
    my $buildargs =
      $meta->find_method_by_name("BUILDARGS");
    if (
        $args eq '@_'
        and ( !$buildargs
            or $buildargs->body == \&MooseX::DBIC::Role::Result::BUILDARGS )
      )
    {
        my @code = ( 'do {',
        'my $params = @_ > 1 ? {@_} : $_[0];',
        );
        my @rels = $meta->get_relationships;
        foreach my $rel (@rels) {
            next unless($rel->has_handles);
            my %handles = $rel->_canonicalize_handles;
            my $name = $rel->name;
            foreach my $handle (keys %handles) {
                push @code, "\$params->{$name}->{$handle} = delete \$params->{$handle} if(exists \$params->{$handle});";
            }
        }
        push @code, (
            'map { delete $params->{$_} } grep { !defined $params->{$_} } keys %$params;',
            '$params', 
        '}');
        return join("\n", @code);
        
    }
    else {
        return $class . "->BUILDARGS($args)";
    }
};

1;
