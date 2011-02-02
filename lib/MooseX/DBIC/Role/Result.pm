package MooseX::DBIC::Role::Result;

use MooseX::DBIC::Role -traits => [qw(MooseX::DBIC::Meta::Role::Class MooseX::ClassAttribute::Trait::Role)];
use Carp;
use DBIx::Class::ResultClass::HashRefInflator;
use Scalar::Util qw(weaken);
use MooseX::DBIC::Util ();
use List::Util ();

__PACKAGE__->meta->add_column( id => (
    required    => 1,
    builder     => '_build_id',
    size        => 10,
    predicate   => 'has_id',
    primary_key => 1,
) );

__PACKAGE__->meta->add_class_attribute( table_name => (
    is => 'rw', isa => 'Str', lazy => 1, builder => '_build_table_name'
) );

__PACKAGE__->meta->add_class_attribute( moniker => (
    is => 'rw', isa => 'Str', default => sub { shift->name }
) );

__PACKAGE__->meta->add_class_attribute( _primaries => (
    is => 'rw', isa => 'Str', default => 'id'
) );

has result_source => ( is => 'rw', init_arg => '-result_source', required => 1, handles => [qw(primary_columns relationship_info)] );

has in_storage => ( is => 'rw', default => 0 );

has _fix_reverse_relationship => ( is => 'rw', predicate => '_clear_fix_reverse_relationship', weak_ref => 1, default => sub {[]} );

has _raw_data => ( is => 'rw', lazy_build => 1 );

has dirty_columns => ( is => 'rw', clearer => 'clear_dirty_columns', default => sub {{}} );

has _inflated_columns => ( is => 'rw', default => sub {{}} );

sub _build__raw_data { return { shift->get_columns } } 

sub resultset { return shift->result_source->schema->resultset(@_) }

sub _build_table_name { 
    (my $table = MooseX::DBIC::Util::decamelize(shift->moniker)) =~ s/::/_/g; $table }

my @chars = ( 'A' .. 'N', 'P' .. 'Z', 0 .. 9 );

sub _build_id {
    my $id;
    $id .= $chars[ int( rand(35) ) ] for ( 1 .. 10 );
    return $id;
}

sub _build_relationship {
    my ($self, $rel, $args) = @_;
    $args ||= {};
    my $method = $rel eq $rel->foreign_key ? 'new_related' : 'find_or_new_related';
    return $self->$method($rel->name, $args);
}

sub _build_related_resultset {
    my ($self, $rel, $args) = @_;
    $args ||= {};
    return $self->search_related($rel->name);
}

sub BUILDARGS { 
    my ($class, @rest) = @_;
    my @rels = $class->meta->get_relationships;
    my $handles = {};
    
    my $args = @rest > 1 ? {@rest} : shift @rest;
    
    my $rs = $args->{'-result_source'};
    
    foreach my $rel(@rels) {
        next unless($rel->has_handles);
        my %def = $rel->_canonicalize_handles;
        map { $handles->{$_} = $rel->name } (keys %def);
    }
    while(my($k,$v) = each %$args) {
        if(exists $handles->{$k}) {
            $args->{$handles->{$k}}->{$k} = delete $args->{$k};
        }
        delete $args->{$k} if(!defined $v);
    }
    return $args;
}

sub BUILD {
    my $self = shift;
    $self->clear_dirty_columns;
    return $self;
}

sub get_column {
    my ($self, $column) = @_;
    if(my $attr = $self->meta->get_column($column)) {
        return $attr->get_raw_value($self);
    }
}

sub get_columns {
    my $self = shift;
    my @columns = $self->meta->get_column_list;
    return map { $_ => $self->meta->get_column($_)->deflate($self) } @columns;
}

sub get_dirty_columns {
    my $self = shift;
    map { $_ => $self->meta->get_column($_)->deflate($self) } $self->meta->get_dirty_column_list($self);
}

# TODO: implement in this class, move stuff to meta class
my %import = (
    'DBIx::Class::Relationship::Base' => [qw(create_related search_related related_resultset find_or_new_related find_related update_or_create_related)],
    'DBIx::Class::PK' => [qw(ident_condition _ident_values)],
    'DBIx::Class::ResultSource' => [qw(_pri_cols resultset_attributes)],
    'Class::Accessor::Grouped' => [qw(get_simple)],
    'DBIx::Class::Row' => [qw(insert_or_update update_or_insert throw_exception)],
);

sub has_column_loaded { 
    my ($self, $column) = @_;
    $column = $self->meta->get_column($column) || return;
    return $column->is_loaded($self);
}

while(my($k,$v) = each %import) {
    Class::MOP::load_class($k);
    foreach my $method (@$v) {
        __PACKAGE__->meta->add_method( $method => \&{$k.'::'.$method} );
    }
}

sub new_related {
    my ( $self, $rel, $values, $attrs ) = @_;
    $rel = $self->meta->get_relationship($rel);
    my $rev = $rel->reverse_relationship;
    if ( $rev && $rev->type ne 'HasMany' ) {
        my $name = $rev->name;
        $values->{$name} = $self;
    }
    my $new =
      $self->search_related( $rel->name )->new_result( $values, $attrs );
    return $new;

}

sub insert {
    my ($self) = @_;
    return $self if $self->in_storage;
    my $source = $self->result_source;
    $self->throw_exception("No result_source set on this object; can't insert")
      unless $source;
    $self->{_update_in_progress} ? return $self : ($self->{_update_in_progress} = 1);
    my %to_insert = $self->get_columns;
    
    my $pk = $self->meta->get_primary_key;
    my $set_pk = ($pk && $pk->auto_increment && !$pk->has_value($self));
    
    delete $to_insert{$pk->name} if($set_pk);
    
    my $updated_cols = $source->storage->insert($source, { %to_insert });
    $self->in_storage(1);

    if($set_pk) {
        my $storage = $self->result_source->storage;
        $self->throw_exception( "Missing primary key but Storage doesn't support last_insert_id" )
          unless $storage->can('last_insert_id');
        my $id = $storage->last_insert_id($self->result_source, $pk->name);
        $self->throw_exception( "Can't get last insert id" )
          unless ($id);
        $pk->set_value($self, $id);
        $to_insert{$pk->name} = $id;
    }

    map { $_->deflate($self) } grep { $_->foreign_key ne $_ } $self->meta->get_all_relationships;
    $self->_raw_data({%to_insert});
    $self->clear_dirty_columns;
    delete $self->{_update_in_progress};
    return $self;
}

sub inflate_result {
    my ($class, $rs, $me, $more, @more) = @_;
    my $hash = DBIx::Class::ResultClass::HashRefInflator::inflate_result(@_);
    $hash = $class->_set_in_storage_deep($hash);
    return $class->new(%$hash, '-result_source' => $rs, _raw_data => $me);
}

sub _set_in_storage_deep {
    my ($self, $data) = @_;
    while(my($k,$v) = each %$data) {
        if(ref $v eq 'ARRAY') {
            $data->{$k} = [ map { $self->_set_in_storage_deep($_) } @$v ];
        } elsif(ref $v eq 'HASH') {
            $data->{$k} = $self->_set_in_storage_deep($v);
        }
    }
    $data->{in_storage} = 1;
    return $data;
}

sub update {
  my ($self, $upd) = @_;
  $self->throw_exception( "Not in database" ) unless $self->in_storage;
  return $self if($self->does('MooseX::DBIC::Meta::Role::ResultProxy'));
  my $ident_cond = $self->ident_condition;
  $self->throw_exception("Cannot safely update a row in a PK-less table")
    if ! keys %$ident_cond;
  $self->{_update_in_progress} ? return $self : ($self->{_update_in_progress} = 1);
  $self->meta->set_columns($self, $upd) if($upd);
  my %to_update = $self->get_dirty_columns;
  
  if(keys %to_update) {
      my $rows = $self->result_source->storage->update(
                   $self->result_source, \%to_update,
                   $self->{_orig_ident} || $ident_cond
                 );
      if ($rows == 0) {
        $self->throw_exception( "Can't update ${self}: row not found" );
      } elsif ($rows > 1) {
        $self->throw_exception("Can't update ${self}: updated more than one row");
      }
  }
  map { $_->deflate($self) } grep { $_->foreign_key ne $_ } $self->meta->get_all_relationships;
  $self->_raw_data({%{$self->_raw_data}, %to_update});
  $self->clear_dirty_columns;
  delete $self->{_update_in_progress};
  return $self;
}

sub delete {
  my $self = shift;
    $self->throw_exception( "Not in database" ) unless $self->in_storage;
    my $ident_cond = $self->{_orig_ident} || $self->ident_condition;
    $self->throw_exception("Cannot safely delete a row in a PK-less table")
      if ! keys %$ident_cond;
      $self->throw_exception("Can't delete the object unless it has loaded the primary keys")
             unless $self->meta->get_primary_key->has_value($self);

    my @cascade = grep { $_->cascade_delete } map { $self->meta->get_relationship($_) } $self->meta->get_relationship_list;
    foreach my $rel(@cascade) {
        $self->search_related($rel->name)->delete_all;
    }
    
    $self->result_source->storage->delete(
      $self->result_source, $ident_cond);
    $self->in_storage(0);

  return $self;
}

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    my $table_name = $self->table_name;
    $sqlt_table->add_index(name => $table_name . '_idx_' . $_->name, fields => ref $_->indexed eq 'ARRAY' ? $_->indexed : [$_->name])
       for(grep { $_->indexed } map { $self->meta->get_column($_) } $self->meta->get_column_list );
}

1;

=head1 ATTRIBUTES

=head2 in_storage

This row is stored and can be updated or deleted.

=head1 METHODS

In order of appearance.

=head2 insert

=head2 update

C<insert> and C<update> work differently in MX::DBIC than they do in DBIC. Instead of working
on the row only, they traverse all relationships and update or insert them as well.

 my $cd = $schema->resultset('CD')->create({ title => 'Big Band Compilation' });
 $cd->artist->name('Mr. Blues'); # will create an artist object
 $cd->update;                    # stores the artist and updates foreign key on $cd

=head2 delete

=head2 new_related

=head2 sqlt_deploy_hook

Iterates over all columns and adds an index to the L<SQL::Translator::Schema::Table> object
if L<MooseX::DBIC::Meta::Role::Column/indexed> has been set.

Add an C<after> modifier to add more thing:

 after sqlt_deploy_hook => sub {
     my ($self, $sqlt_table) = @_;
     $sqlt_table->add_constraint( ... );
 };
 
=head1 IMPORTED METHODS

These methods have been imported from DBIC

=head2 related_resultset 

See L<DBIx::Class::Relationship::Base/related_resultset>.

=head2 search_related

See L<DBIx::Class::Relationship::Base/search_related>.

=head2 create_related

See L<DBIx::Class::Relationship::Base/create_related>.

=head2 find_or_new_related 

See L<DBIx::Class::Relationship::Base/find_or_new_related>.

=head2 find_related 

See L<DBIx::Class::Relationship::Base/find_related>.

=head2 update_or_create_related

See L<DBIx::Class::Relationship::Base/update_or_create_related>.

=head2 ident_condition 

See L<DBIx::Class::PK/ident_condition>.

=head2 _ident_values

See L<DBIx::Class::PK/_ident_values>.

=head2 _pri_cols 

See L<DBIx::Class::ResultSource/_pri_cols>.

=head2 resultset_attributes

See L<DBIx::Class::ResultSource/resultset_attributes>.

=head2 get_simple

See L<Class::Accessor::Grouped/get_simple>.

=head2 insert_or_update

=head2 update_or_insert

See L<DBIx::Class::Row/insert_or_update>.

=head2 throw_exception

See L<DBIx::Class::Row/throw_exception>.


=head1 COMPATIBILITY METHODS

Those methods were added to make DBIC work with the result class.
They usually call a method on the meta class. They might go away in future releases
so call them on the meta class.

=head2 get_column

=head2 get_columns

=head2 get_dirty_columns

=head2 has_column_loaded

See L<MooseX::DBIC::Meta::Role::Column/is_loaded>.

=head1 INTERNAL METHODS

=head2 inflate_result

=head2 _set_in_storage_deep
