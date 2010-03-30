package MooseX::DBIC::Result;

use Moose::Role;
use MooseX::DBIC;

has_column id => (
    isa         => 'Str',
    required    => 1,
    is          => 'rw',
    builder     => '_build_id',
    column_info => { data_type => 'character', size => 10 },
);

has result_source => ( is => 'rw', init_arg => '-result_source', required => 1 );

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
    return $self->resultset($rel->related_source)->new_result($args);
}

sub _build_related_resultset {
    my ($self, $rel, $args) = @_;
    $args ||= {};
    return $self->search_related($rel->name, { $rel->name.'.'.$self->dbic_result_class->table => $self->id });
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
            $args->{$name} = $rs->schema->resultset($rel->related_source)->new_result($args->{$name});
        } elsif(ref $args->{$name} eq "ARRAY") {
            $_ = $rs->schema->resultset($rel->related_source)->new_result($_) for(@{$args->{$name}});
        }
    }
    
    return $args;
}

sub search_related {
    my $self = shift;
    return $self->result_source->resultset->search_related(@_);
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
    use Data::Dumper; warn Dumper \@more;
    my %new = ('-result_source' => $rs);
    while(my($k,$v) = each %$me) {
        my $attr = $class->meta->get_attribute($k);
        $new{$k} = $attr->inflate($class, $v, undef, $rs, $attr) if(defined $v);
    }
    return $class->new(%new);
}

1;
