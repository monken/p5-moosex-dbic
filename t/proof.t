package MyApp::User;
use Moose;

has [qw(first last email)] => ( is => 'rw', isa => 'Str', );


package main;

use SQL::Translator;
use Moose;
use MooseX::NonMoose;
use Moose::Meta::Class;

my $schema = Moose::Meta::Class->create_anon_class(
    superclasses => [qw(DBIx::Class::Schema)],
    cache => 1,
)->name;

my $user = Moose::Meta::Class->create_anon_class(
    superclasses => [qw(DBIx::Class::Core)],
    cache => 1,
)->name;

$user->table('user');
$user->add_columns(qw(id first last email));
# $user isa DBIx::Class::ResultSource
$user->set_primary_key(qw(id));


$schema->register_class(User => $user);

$schema = $schema->connect( 'dbi:SQLite:dbname=:memory:' );

$schema->deploy;