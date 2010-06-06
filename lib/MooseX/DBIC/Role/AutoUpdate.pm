package MooseX::DBIC::Role::AutoUpdate;

use Moose::Role;

sub DEMOLISH {
    my $self = shift;
    $self->update if($self->in_storage && !$self->does('MooseX::DBIC::Meta::Role::ResultProxy'));
}

1;

__END__

=head1 SYNOPSIS

 package MySchema::User;
 use MooseX::DBIC;
 with 'AutoUpdate';
 
 has_column 'name';
 
 1;
 
 $schema->resultset('User')->create({ name => 'Peter' });
 {
    my $user = $schema->resultset('User')->first;
    $user->name('Hans');
 }
 # $user ran out of scope and will be updated automatically
 # on destruction, no need to call $user->update
 
 # $schema->resultset('User')->first->name is now "Hans"

=head1 DESCRIPTION

This module makes calls to L<MooseX::DBIC::Role::Result/update>
obsolete. On destruction the row's update method is called and
thus changes to it are written to the database. Since this
is not always the desired behaviour, this is an optional role and
not applied by default.

Call L<MooseX::DBIC::Role::Result/discard_changes> to discard any
changes and prevent this role from calling update.