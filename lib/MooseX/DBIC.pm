package MooseX::DBIC;
# ABSTRACT: DBIC result class based on Moose
use Moose ();
use MooseX::DBIC::Meta::Role::Class;
use MooseX::DBIC::Types qw(ResultSet);
use Moose::Exporter;

my ( $import, $unimport, $init_meta ) = Moose::Exporter->build_import_methods(
    also => 'Moose',
    with_meta =>
      [qw(has_column has_many belongs_to has_one might_have table remove with)],
    as_is           => [qw(ResultSet)],
    class_metaroles => {
        class => [
            qw(MooseX::DBIC::Meta::Role::Class MooseX::ClassAttribute::Trait::Class)
        ],
        instance => [qw(MooseX::DBIC::Meta::Role::Instance)],
        constructor =>
          [
           'MooseX::Attribute::LazyInflator::Meta::Role::Method::Constructor'
           #'MooseX::DBIC::Meta::Role::Method::Constructor'
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
    $meta->meta->superclasses($meta->meta->superclasses, 'DBIx::Class::ResultSource');
    return $meta;
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

 package CD;
 use MooseX::DBIC;
    
 has_column 'title';
 belongs_to artist => ( isa => 'Artist' );
 
 package Artist;
 use MooseX::DBIC;    
 
 has_column 'name';
 has_many cds => ( isa => ResultSet['CD'] );
 
 package MySchema;
 use Moose;
 extends 'MooseX::DBIC::Schema';
 
 __PACKAGE__->load_classes(qw(Artist CD));
 
 package main;
 
 my $schema = MySchema->connect( 'dbi:SQLite::memory:' );
 
 $schema->deploy;
 
 my $artist = $schema->resultset('Artist')->create(
    { 
      name => 'Mo',
      cds => [ { title => 'Sound of Moose' } ]
    }
 );

=head1 PRINCIPLES

=over 4

=item B<Convention over Configuration>

=item B<Mandatory Primary Key>

All tables you create using L<MooseX::DBIC> have a primary key C<id>.
It is not an auto incrementing integer but a random string.

Creating tables without a primary key is not supported.

=item B<Single Primary Keys>

Tables with multiple primary keys are not supported.

=back

=head1 RESULT DEFINITION

 package MyApp::Artist;
 use MooseX::DBIC;

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

Remove a previously added column. Can be used to remove the default primary key column C<id>.

=item B<< has_many >>

 has_many cds => ( isa => ResultSet['MyApp::CD'] );

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

=back

=head1 INTROSPECTION

  my $meta = MyApp::Artist->meta;
  
See L<MooseX::DBIC::Meta::Role::Class>.
