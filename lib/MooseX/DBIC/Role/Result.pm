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

__PACKAGE__->meta->add_class_attribute( _orig => (
    is => 'rw', isa => 'Str'
) );

__PACKAGE__->meta->add_class_attribute( _primaries => (
    is => 'rw', isa => 'Str', default => 'id'
) );

has result_source => ( is => 'rw', init_arg => '-result_source', required => 1, handles => [qw(primary_columns relationship_info)] );

has in_storage => ( is => 'rw', isa => 'Bool', default => 0 );

has _fix_reverse_relationship => ( is => 'rw', predicate => '_clear_fix_reverse_relationship', weak_ref => 1, default => sub {[]} );

has _raw_data => ( is => 'rw', isa => 'HashRef', lazy_build => 1 );

has dirty_columns => ( is => 'rw', isa => 'HashRef', clearer => 'clear_dirty_columns', default => sub {{}} );

has _inflated_columns => ( is => 'rw', isa => 'HashRef', default => sub {{}} );

sub _build__raw_data { return { shift->get_columns } } 

sub resultset { return shift->result_source->schema->resultset(@_) }

sub _build_table_name { 
    (my $table = MooseX::DBIC::Util::decamelize(shift->moniker)) =~ s/::/_/g; $table }

sub _build_id {
    my @chars = ( 'A' .. 'N', 'P' .. 'Z', 0 .. 9 );
    my $id;
    $id .= $chars[ int( rand(@chars) ) ] for ( 1 .. 10 );
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
        map { $handles->{$_} = $rel->name } @{$rel->handles || []};
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

sub search_related {
  return shift->related_resultset(shift)->search(@_);
}

# TODO: implement in this class, move stuff to meta class
my %import = (
    'DBIx::Class::Relationship::Base' => [qw(related_resultset find_or_new_related find_related)],
    'DBIx::Class::PK' => [qw(ident_condition _ident_values)],
    'DBIx::Class::ResultSource' => [qw(_pri_cols )],
    'Class::Accessor::Grouped' => [qw(get_simple)],
    'DBIx::Class::Row' => [qw(throw_exception)],
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
  my ($self, $rel, $values, $attrs) = @_;
  $rel = $self->meta->get_relationship($rel);
  my $rev = $rel->reverse_relationship;
  if($rev && $rev->type ne 'HasMany') {
    my $name = $rev->name;
    $values->{$name} = $self;
  }
  my $new = $self->search_related($rel->name)->new_result($values, $attrs);
  return $new;
  
}

sub create_related { return shift->new_related(@_)->insert; }


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

sub update_or_insert {
    my $self = shift;
    return ( $self->in_storage ? $self->update : $self->insert );
}

*insert_or_update = \&update_or_insert;

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


1;
