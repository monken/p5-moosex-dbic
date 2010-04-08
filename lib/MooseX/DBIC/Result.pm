package MooseX::DBIC::Result;

use Moose::Role;
use MooseX::DBIC;
use Carp;
use DBIx::Class::ResultClass::HashRefInflator;
use Scalar::Util qw(weaken);

has_column id => (
    isa         => 'Str',
    required    => 1,
    is          => 'rw',
    builder     => '_build_id',
    column_info => { data_type => 'character', size => 10 },
);


has result_source => ( is => 'rw', init_arg => '-result_source', required => 1, handles => [qw(primary_columns relationship_info)] );

has in_storage => ( is => 'rw', isa => 'Bool' );

has _fix_reverse_relationship => ( is => 'rw', predicate => '_clear_fix_reverse_relationship', weak_ref => 1, default => sub {[]} );

has _raw_data => ( is => 'rw', isa => 'HashRef', lazy_build => 1 );

sub _build__raw_data { return { shift->get_columns } } 

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
    my @rels = map { $class->meta->get_attribute($_) } $class->meta->get_relationship_list;
    my $handles = {};
    
    my $args = @rest > 1 ? {@rest} : shift @rest;
    #warn Data::Dumper::Dumper $args;
    my $rs = $args->{'-result_source'};
    $args->{_fix_reverse_relationship} = [];
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
        my $value = $args->{$name};
        if($rel->type eq 'HasMany') {
            $value = [ $value ] unless( ref $value eq 'ARRAY' );
            my @rows = map { ref $_ eq "ARRAY" ? $_->[0] : $_ } @$value;
            my $resultset = $rs->schema->resultset($rel->related_class);
            @rows =  map { ref $_ eq 'HASH' ? $resultset->new_result($_) : $_ } @rows;
            $resultset->set_cache(\@rows);
            $args->{$name} = $resultset;
            push(@{$args->{_fix_reverse_relationship}}, map { $rel, $_ } @rows);
        } else {
            $value = $value->[0] if(ref $value eq 'ARRAY' );
            if(!defined $value) {
                delete $args->{$name};
                next;
            } elsif(ref $value eq "HASH") {
                $args->{$name} = $rs->schema->resultset($rel->related_class)->new_result($value);
            }  elsif(!ref $value && defined $value) {
                my $attr = $class->meta->get_attribute($name);
                $args->{$name} = $attr->inflate($class, $value, undef, $rs, $attr);
                $args->{$name}->in_storage(1);
            
            }
            push(@{$args->{_fix_reverse_relationship}}, $rel, $args->{$name});
        }
    }
    
    while(my($k,$v) = each %$args) {
        my $attr = $class->meta->find_attribute_by_name($k);
        next unless($attr && $attr->does('MooseX::Attribute::Deflator::Meta::Role::Attribute'));
        $args->{$k} = $attr->inflate($class, $v, undef, $rs, $attr) if(!ref $v);
        delete $args->{$k} if(!defined $args->{$k});
    }
    return $args;
}

sub BUILD {
    my $self = shift;
    return if($self->does('MooseX::DBIC::Meta::Role::ResultProxy'));
    my @fix = @{ $self->_fix_reverse_relationship };
    for(my $i = 0; $i < @fix; $i+=2) {
        my ($relationship, $fix) = ($fix[$i], $fix[$i+1]);
        next if($fix->does('MooseX::DBIC::Meta::Role::ResultProxy'));
        next if($relationship->associated_class && # FIXME: How can associated_class be undef?
                $relationship->associated_class == $relationship->foreign_key->associated_class);
        my $name = $relationship->foreign_key->name;
        $fix->$name($self);
        $relationship->foreign_key->_weaken_value($fix);
        $fix->in_storage(1) if($self->in_storage);
    }
    $self->_clear_fix_reverse_relationship;
    #$self->_raw_data if($self->in_storage);
    return $self;
}

sub get_column {
    my ($self, $column) = @_;
    return $self->$column;
}

sub get_columns {
    my $self = shift;
    my @columns = $self->meta->get_column_list;
    return map { $_ => $self->meta->get_attribute($_)->deflate($self) } @columns;
}

sub get_dirty_columns {
    my $self = shift;
    my $raw = $self->_raw_data;
    my %dirty = $self->get_columns;
    while(my ($k,$v) = each %dirty) {
        delete $dirty{$k} if(defined $v && defined $raw->{$k} && $v."" eq $raw->{$k}."");
        delete $dirty{$k} if(!defined $v && !defined $raw->{$k});
    }
    return %dirty;
    
}

sub search_related {
  return shift->related_resultset(shift)->search(@_);
}

# TODO: implement in this class, move stuff to meta class
my %import = (
    'DBIx::Class::Relationship::Base' => [qw(related_resultset find_or_new_related find_related)],
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
    Class::MOP::load_class($k);
    foreach my $method (@$v) {
        __PACKAGE__->meta->add_method( $method => \&{$k.'::'.$method} );
    }
}

sub new_related {
  my ($self, $rel, $values, $attrs) = @_;
  my $new = $self->search_related($rel)->new_result($values, $attrs);
  $rel = $self->meta->get_relationship($rel);
  my $rev = $rel->reverse_relationship;
  if($rev && $rev->type ne 'HasMany') {
      my $name = $rev->name;
      $new->$name($self);
  }
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
    my $updated_cols = $source->storage->insert($source, { %to_insert });
    $self->in_storage(1);
    map { $_->deflate($self) } grep { $_->foreign_key ne $_ } $self->meta->get_all_relationships;
    $self->_raw_data({%to_insert});
    undef $self->{_update_in_progress};
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
    return $class->new(%$hash, '-result_source' => $rs, in_storage => 1, _raw_data => $me);
}

sub update {
  my ($self, $upd) = @_;
  $self->throw_exception( "Not in database" ) unless $self->in_storage;
  my $ident_cond = $self->ident_condition;
  $self->throw_exception("Cannot safely update a row in a PK-less table")
    if ! keys %$ident_cond;
  $self->{_update_in_progress} ? return $self : ($self->{_update_in_progress} = 1);
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
  undef $self->{_update_in_progress};
  return $self;
}


1;
