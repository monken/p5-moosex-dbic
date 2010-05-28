package MooseX::DBIC::Util;

# from String::CamelCase

sub camelize {
	my $s = shift;
	join('', map{ ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s));
}


sub decamelize {
	my $s = shift;
	$s =~ s{([^a-zA-Z]?)([A-Z]*)([A-Z])([a-z]?)}{
		my $fc = pos($s)==0;
		my ($p0,$p1,$p2,$p3) = ($1,lc$2,lc$3,$4);
		my $t = $p0 || $fc ? $p0 : '_';
		$t .= $p3 ? $p1 ? "${p1}_$p2$p3" : "$p2$p3" : "$p1$p2";
		$t;
	}ge;
	$s;
}

sub find_result_class {
    my $class = shift;
    if(!ref $class) {
    } elsif($class->isa('Moose::Meta::TypeConstraint::Parameterized')) {
        $class = find_result_class($class->type_parameter);
    } elsif($class->isa('Moose::Meta::TypeConstraint::Class')) {
        $class = $class->class;
    }
    Class::MOP::load_class($class);
    return $class if($class->isa('Moose::Object') && $class->does('MooseX::DBIC::Role::Result'));
    
}


1;