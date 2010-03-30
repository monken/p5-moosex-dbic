package MooseX::DBIC::Result;

use Moose::Role;
use MooseX::DBIC;

has_column id => (
    isa         => 'Str',
    required    => 1,
    is          => 'rw',
    builder     => '_build_id',
    column_info => { data_type => 'character', size => 10 }
);

has result_source => ( is => 'rw', init_arg => '-result_source' );

has in_storage => ( is => 'rw', isa => 'Bool' );

sub _build_id {
    my @chars = ( 'A' .. 'N', 'P' .. 'Z', 0 .. 9 );
    my $id;
    $id .= $chars[ int( rand(@chars) ) ] for ( 1 .. 10 );
    return $id;
}

sub _build_relationship { 1 }

sub get_columns {
    my $self = shift;
    my @columns = $self->meta->get_column_attribute_list;
    warn @columns;
    return map { $_ => $self->$_ } @columns;
}

sub insert {
    my ($self) = @_;
    return $self if $self->in_storage;
    my $source = $self->result_source;
    $self->throw_exception("No result_source set on this object; can't insert")
      unless $source;
    my $updated_cols = $source->storage->insert($source, { $self->get_columns });

}

sub insert_or_update { shift->update_or_insert(@_) }

sub update_or_insert {
    my $self = shift;
    return ( $self->in_storage ? $self->update : $self->insert );
}

sub inflate_result {
    my ($class, $rs, $me, $more) = @_;
    die if($more);
    my %new;
    while(my($k,$v) = each %$me) {
        $new{$k} = $v if(defined $v);
    }
    return $class->new(%new);
}

1;
