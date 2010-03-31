package MooseX::DBIC::Result;

use Moose::Role;
use MooseX::DBIC;
#use MooseX::ClassAttribute;

#class_has schema_class => ( is => 'rw', isa => 'Str' );

has_column id => (
    isa         => 'Str',
    required    => 1,
    is          => 'rw',
    builder     => '_build_id',
    column_info => { data_type => 'character', size => 10 },
);


has result_source => ( is => 'rw', init_arg => '-result_source', required => 1, handles => [qw(primary_columns relationship_info)] );

has in_storage => ( is => 'rw', isa => 'Bool' );

sub resultset { return shift->result_source->schema->resultset(@_) }

sub _build_id {
    my @chars = ( 'A' .. 'N', 'P' .. 'Z', 0 .. 9 );
    my $id;
    $id .= $chars[ int( rand(@chars) ) ] for ( 1 .. 10 );
    return $id;
}

sub _build_relationship {
    my ($self, $rel, $args) = @_;
    $args ||= {};
    return $self->resultset($rel->related_class->dbic_result_class)->new_result($args);
}

sub _build_related_resultset {
    my ($self, $rel, $args) = @_;
    $args ||= {};
    return $self->search_related($rel->name);
}

sub BUILDARGS { 
    my ($class, @rest) = @_;
    my @rels = map { $class->meta->get_attribute($_) } $class->meta->get_relationship_list;
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
    }
    foreach my $rel(@rels) {
        my $name = $rel->name;
        next unless(exists $args->{$name});
        if(ref $args->{$name} eq "HASH") {
            $args->{$name} = $rs->schema->resultset($rel->related_class->dbic_result_class)->new_result($args->{$name});
        } elsif(ref $args->{$name} eq "ARRAY") {
            my $resultset = $rs->schema->resultset($rel->related_class);
            my @rows = [ map { $resultset->new_result($_) } grep { defined $_->{id} } @{$args->{$name}} ];
            $resultset->set_cache(\@rows);
            $args->{$name} = $resultset;
        } elsif(!ref $args->{$name}) {
            my $attr = $class->meta->get_attribute($name);
            $args->{$name} = $attr->inflate($class, $args->{$name}, undef, $rs, $attr) if(defined $args->{$name});
        }
    }
    return $args;
}

sub get_column{
    my ($self, $column) = @_;
    return $self->$column;
}

sub get_dirty_columns {()}

sub search_related {
  return shift->related_resultset(shift)->search(@_);
}

# implement in this class, move stuff to meta class
my %import = (
    'DBIx::Class::Relationship::Base' => [qw(related_resultset)],
    'DBIx::Class::PK' => [qw(ident_condition _ident_values)],
    'DBIx::Class::ResultSource' => [qw(_pri_cols _primaries)],
    'Class::Accessor::Grouped' => [qw(get_simple)],
    'DBIx::Class::Row' => [qw(throw_exception)],
    
);

sub has_column_loaded { 
    my ($self, $column) = @_;
    return $self->meta->get_attribute($column)->has_value($self);
}

while(my($k,$v) = each %import) {
foreach my $method (@$v) {
    __PACKAGE__->meta->add_method( $method => \&{$k.'::'.$method} );
}
}

sub new_related {
  my ($self, $rel, $values, $attrs) = @_;
  return $self->search_related($rel)->new($values, $attrs);
}

sub create_related {
  my $self = shift;
  my $rel = shift;
  my $obj = $self->search_related($rel)->create(@_);
  # delete $self->{related_resultsets}->{$rel}; FIXME: What is this?
  return $obj;
}


sub get_columns {
    my $self = shift;
    my @columns = $self->meta->get_column_attribute_list;
    return map { $_ => $self->meta->get_attribute($_)->deflate($self) } @columns;
}

sub insert {
    my ($self) = @_;
    return $self if $self->in_storage;
    my $source = $self->result_source;
    $self->throw_exception("No result_source set on this object; can't insert")
      unless $source;
    my $updated_cols = $source->storage->insert($source, { $self->get_columns });
    $self->in_storage(1);
    return $self;
}

sub insert_or_update { shift->update_or_insert(@_) }

sub update_or_insert {
    my $self = shift;
    return ( $self->in_storage ? $self->update : $self->insert );
}

sub inflate_result {
    my ($class, $rs, $me, $more, @more) = @_;
    $me = {%$me, %$more} if($more);
    my %new = ('-result_source' => $rs, in_storage => 1);
    while(my($k,$v) = each %$me) {
        my $attr = $class->meta->get_attribute($k);
        $new{$k} = $attr->inflate($class, $v, undef, $rs, $attr) if(defined $v);
    }
    return $class->new(%new);
}

sub update {
  my ($self, $upd) = @_;
  $self->throw_exception( "Not in database" ) unless $self->in_storage;
  my $ident_cond = $self->ident_condition;
  $self->throw_exception("Cannot safely update a row in a PK-less table")
    if ! keys %$ident_cond;

  $self->set_inflated_columns($upd) if $upd;
  my %to_update = $self->get_dirty_columns;
  return $self unless keys %to_update;
  my $rows = $self->result_source->storage->update(
               $self->result_source, \%to_update,
               $self->{_orig_ident} || $ident_cond
             );
  if ($rows == 0) {
    $self->throw_exception( "Can't update ${self}: row not found" );
  } elsif ($rows > 1) {
    $self->throw_exception("Can't update ${self}: updated more than one row");
  }
  $self->{_dirty_columns} = {};
  $self->{related_resultsets} = {};
  undef $self->{_orig_ident};
  return $self;
}


1;
