package MooseX::DBIC;
# ABSTRACT: DBIC result class based on Moose
use Moose ();
use MooseX::DBIC::Meta::Role::Class;
use MooseX::DBIC::Types qw(ResultSet);
use Moose::Exporter;

my ( $import, $unimport, $init_meta ) = Moose::Exporter->build_import_methods(
    also => 'Moose',
    with_meta =>
      [qw(has_column has_many belongs_to has_one might_have table remove with class_has)],
    as_is           => [qw(ResultSet)],
    class_metaroles => {
        class => [
            qw(MooseX::DBIC::Meta::Role::Class MooseX::ClassAttribute::Trait::Class)
        ],
        instance => [qw(MooseX::DBIC::Meta::Role::Instance)],
        constructor =>
          [
           'MooseX::Attribute::LazyInflator::Meta::Role::Method::Constructor',
           'MooseX::DBIC::Meta::Role::Method::Constructor'
          ],
    },
    install => [qw(import unimport init_meta)]
);


sub with {
    my ($meta, $role) = @_;
    eval {
        Moose::with($meta, 'MooseX::DBIC::Role::' . $role);
    } or do {
        die $@ if($@ !~ /^Can't locate/);
        Moose::with($meta, $role);
    }
}

sub init_meta {
    my $package = shift;
    my %options = @_;
    Moose->init_meta(%options);
    my $meta = $package->$init_meta(%options);
    Moose::Util::ensure_all_roles($options{for_class}, 'MooseX::DBIC::Role::Result');
    Moose::Util::ensure_all_roles($options{for_class}, 'MooseX::Attribute::LazyInflator::Role::Class');
    return $meta;
}

sub class_has {
    my $meta    = shift;
    my $name    = shift;
    my %options = @_;

    my $attrs = ref $name eq 'ARRAY' ? $name : [$name];

    $meta->add_class_attribute( $_, %options ) for @{$attrs};
}

sub table {
    shift->set_class_attribute_value( 'table_name', shift);
}

sub has_column {
    shift->add_column(@_);
}

sub remove {
    shift->remove_column(shift);
}

sub has_many {
    shift->add_relationship(@_, type => 'HasMany');
}

sub belongs_to {
    shift->add_relationship(@_, type => 'BelongsTo');
}

sub might_have {
    shift->add_relationship(@_, type => 'MightHave');
}

sub has_one {
    shift->add_relationship(@_, type => 'HasOne');
}

1;

__END__

=head1 SYNOPSIS

 package MySchema::CD;
 use MooseX::DBIC;
    
 has_column 'title';
 belongs_to artist => ( isa => 'Artist' );
 
 package MySchema::Artist;
 use MooseX::DBIC;    
 
 has_column 'name';
 has_many cds => ( isa => 'CD' );
 
 package MySchema;
 use Moose;
 extends 'MooseX::DBIC::Schema';
 
 __PACKAGE__->load_namespaces();
 
 package main;
 
 my $schema = MySchema->connect( 'dbi:SQLite::memory:' );
 
 $schema->deploy;
 
 my $artist = $schema->resultset('Artist')->create(
    { 
      name => 'Mo',
      cds => [ { title => 'Sound of Moose' } ]
    }
 );
 
 my @artists = $schema->resultset('Artist')->order_by('name')->prefetch('cd')->all;

=head1 PRINCIPLES

=over 4

=item B<Convention over Configuration>

=item B<Mandatory Single Primary Key>

All tables you create using L<MooseX::DBIC> have a primary key C<id>.
It is not an auto incrementing integer but a random string (thoguh this can be changed).

Creating tables with more than one or none primary key is not supported.

=back

=head1 RESULT DEFINITION

 package MyApp::Artist;
 use MooseX::DBIC;
 
 # column and realtionship definition
 
 __PACKAGE__->meta->make_immutable; # speed

=over 4

=item B<< table >>

  table 'mytable';
  
Specifying a table name is optional. By default MooseX::DBIC will use the package name as 
table name. A package C<MyApp::User> will lead to a table name of C<myapp_user>.

=item B<< has_column >>

 has_column 'name';
  
 use MooseX::Types::Email qw(EmailAddress);
  
 has_column email => ( isa => EmailAddress );

Add a column to the result class. See L<MooseX::DBIC::Meta::Role::Column> for
further details. 
  
=item B<< remove >>

 remove 'id';
 has_column mypk => ( primary_key => 1, auto_increment => 1, isa => 'Int' );

Remove a previously added column. Can be used to remove the default primary key column C<id>.

=item B<< has_many >>

 has_many cds => ( isa => 'MyApp::CD' );

See L<MooseX::DBIC::Meta::Role::Relationship::HasMany>.

=item B<< belongs_to >>

 belongs_to producer => ( isa => 'MyApp::Producer' );

See L<MooseX::DBIC::Meta::Role::Relationship::BelongsTo>.

=item B<< might_have >>

 might_have artwork => ( isa => 'MyApp::Artwork' );

See L<MooseX::DBIC::Meta::Role::Relationship::MightHave>.

=item B<< has_one >>

 has_one mandatory_artwork => ( isa => 'MyApp::Artwork' );

See L<MooseX::DBIC::Meta::Role::Relationship::HasOne>.

=item B<< with >>

 with 'AutoUpdate';
 with 'MooseX::DBIC::Role::AutoUpdate';  # same as above

This is the preferred way to apply roles to the class. L<with|Moose/EXPORTED FUNCTIONS>
has been overridden to allow for a shorter syntax.

See the L<MooseX::DBIC::Role::> namespace for more roles.

=back

=head1 INTROSPECTION

One of the big advantages that come with Moose is the ability to introspect 
classes, attributes and pretty much everything. MooseX::DBIC adds methods to
the meta class to get easy access to columns, relationships and more.

  my $meta = MyApp::Artist->meta;
  
Check out L<MooseX::DBIC::Meta::Role::Class> to get started.
