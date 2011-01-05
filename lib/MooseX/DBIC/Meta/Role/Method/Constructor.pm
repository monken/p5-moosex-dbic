package MooseX::DBIC::Meta::Role::Method::Constructor;

use Moose::Role;

# sub BUILDARGS {
#     my ($class, @rest) = @_;
#     my @rels = $class->meta->get_relationships;
#     my $handles = {};
#
#     my $args = @rest > 1 ? {@rest} : shift @rest;
#
#     my $rs = $args->{'-result_source'};
#
#     foreach my $rel(@rels) {
#         map { $handles->{$_} = $rel->name } @{$rel->handles || []};
#     }
#     while(my($k,$v) = each %$args) {
#         if(exists $handles->{$k}) {
#             $args->{$handles->{$k}}->{$k} = delete $args->{$k};
#         }
#         delete $args->{$k} if(!defined $v);
#     }
#     return $args;
# }

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
            next unless(my $handles = $rel->handles || []);
            my $name = $rel->name;
            foreach my $handle (@$handles) {
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
