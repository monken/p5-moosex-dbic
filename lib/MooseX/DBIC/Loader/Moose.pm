package MooseX::DBIC::Loader::Moose;

use MooseX::Role::Parameterized;

parameter classes => ( isa => 'ArrayRef', required => 1, );

parameter target_namespace => ( isa => 'Str',  );


role {
    my $p = shift;
    my $ns = $p->target_namespace;
    _load_moose_class($ns, $_) for(@{$p->classes || []});
        
    sub _load_moose_class {
        my ( $schema, $class ) = @_;

        my $result =  $schema . '::' . $class;
        Class::MOP::load_class($class);
        
        my $instance_metaclass = $class->meta->create_anon_class(
            superclasses => [ $class->meta->instance_metaclass ],
            roles => [qw(MooseX::DBIC::Meta::Role::Instance)],
            cache => 1,
        )->name;

        my $result_metaclass = $class->meta->create_anon_class(
            superclasses => [ $class->meta->meta->name ],
            roles => [qw(MooseX::DBIC::Meta::Role::Class MooseX::ClassAttribute::Trait::Class)],
            cache        => 1,
        )->name;
        
        my @superclasses = map {
            _load_moose_class($schema, $_)
              unless ( $schema->is_class_loaded($_) );
            join( '::', $schema, $_);
        } $class->meta->superclasses;
        
        #Moose::Meta::Class->initialize($result, instance_metaclass => $instance_metaclass);
        
        $result_metaclass->create(
            $result,
            superclasses => [ $class, @superclasses, ],
            roles => ['MooseX::DBIC::Role::Result'],
            cache        => 1,
        );
        
        
        
        Moose::Util::ensure_all_roles($result, 'MooseX::Attribute::LazyInflator::Role::Class');

        foreach my $attr ( $class->meta->get_attribute_list ) {
            my $attribute = $class->meta->get_attribute($attr);
            $result->meta->add_attribute(
                $attribute->clone_and_inherit_options( 
                    traits => [
                     qw(MooseX::DBIC::Meta::Role::Column
                        MooseX::Attribute::Deflator::Meta::Role::Attribute)]
                )
            );
            push(@{$result->meta->column_list}, $attr);
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