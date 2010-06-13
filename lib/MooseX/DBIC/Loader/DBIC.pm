package MooseX::DBIC::Loader::DBIC;

use MooseX::Role::Parameterized;

parameter classes => ( isa => 'ArrayRef', required => 1, );

parameter target_namespace => ( isa => 'Str',  );


role {
    my $p = shift;
    my $ns = $p->target_namespace;
    _load_dbic_class($ns, $_) for(@{$p->classes || []});
        
    sub _load_dbic_class {
        my ( $schema, $class ) = @_;

        my $result =  $schema . '::' . $class;
        Class::MOP::load_class($class);
        
        my $result_metaclass = Moose::Meta::Class->create_anon_class(
            superclasses => [ 'Moose::Meta::Class' ],
            roles => [qw(MooseX::DBIC::Meta::Role::Class MooseX::ClassAttribute::Trait::Class)],
            cache        => 1,
        )->name;
        
        $result_metaclass->create(
            $result,
            superclasses => [ 'Moose::Object' ],
            roles => ['MooseX::DBIC::Role::Result'],
            cache        => 1,
        );

        return $result;

    };
};


1;