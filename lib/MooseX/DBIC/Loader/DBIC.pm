package MooseX::DBIC::Loader::Moose;

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
        
        warn Data::Dumper::Dumper $class->result_source;
        
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

        foreach my $col ( $class->result_source ) {
            my $attribute = $class->meta->get_attribute($attr);
            $result->meta->add_attribute(
                $attribute->clone_and_inherit_options( 
                    traits => [
                     qw(MooseX::DBIC::Meta::Role::Column
                        MooseX::Attribute::Deflator::Meta::Role::Attribute)]
                )
            );
        }

        foreach my $superclass ($class->meta->superclasses) {
            _load_moose_class($schema, $superclass)
              unless ( $schema->is_class_loaded($superclass) );
            my $related = join( '::', $schema, $superclass);
            ( my $table = lc($superclass) ) =~ s/::/_/g;
            $result->meta->add_relationship($table => ( type => 'HasSuperclass', isa => $related));
        }
       

        return $result;

    };
};


1;