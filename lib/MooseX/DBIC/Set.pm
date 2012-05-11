package MooseX::DBIC::Set;
use Moose;
extends 'DBIx::Class::ResultSet';
use DBIx::Class::ResultClass::HashRefInflator;
use List::MoreUtils qw(uniq);

sub postfetch {
    my ( $self, $rel_name, $search ) = @_;
    $search ||= {};
    my @objects      = $self->all;
    my $result_class = $self->result_class->meta;
    my $rel          = $result_class->get_relationship($rel_name);
    my $rel_pk       = $rel->related_class->meta->get_primary_key->name;
    my $pk           = $result_class->get_primary_key;
    my $pk_name      = $pk->name;
    my $schema       = $self->result_source->schema;
    my $related = $schema->resultset( $rel->related_class )->search($search);
    my $fk      = $rel->foreign_key;
    my $fk_name = $fk->name;

    if ( $fk->associated_class == $result_class ) {

        # belongs_to
        my @ids = uniq map { $rel->get_raw_value($_) } @objects;
        $related = $related->search(
            {   $related->current_source_alias
                    . ".$rel_pk" => { -in => \@ids }
            }
        );
        my %related = map { $_->$rel_pk => $_ } $related->all;
        foreach my $object (@objects) {
            next unless ( defined( my $id = $rel->get_raw_value($object) ) );
            next unless ( $related{$id} );
            $rel->set_raw_value( $object, $related{$id} );
            $object->_inflated_attributes->{ $rel->name }++;
        }
    }
    else {
        my $has_many = $rel->type eq 'HasMany';
        my @ids = uniq map { $pk->get_raw_value($_) } @objects;
        $related = $related->search(
            {   join( ".", $related->current_source_alias, $fk->name ) =>
                    { -in => \@ids }
            }
        );

        my %objects_cache = map { $_->$pk_name => [] } @objects if $has_many;
        my %objects = map { $_->$pk_name => $_ } @objects;

        if ($has_many) {

            # init empty resultset cache
            foreach my $object (@objects) {
                my $rs = $schema->resultset( $rel->related_class );
                $rs->set_cache( $objects_cache{ $object->$pk_name } );
                $rel->set_raw_value( $object, $rs );
            }
        }

        while ( my $row = $related->next ) {
            my $id = $fk->get_raw_value($row);
            if ($has_many) {
                push( @{ $objects_cache{$id} }, $row );
            }
            else {
                $rel->set_raw_value( $objects{$id}, $row );
                $objects{$id}->_inflated_attributes->{ $rel->name }++;
            }

            $fk->set_raw_value( $row, $objects{$id} );
            $fk->_weaken_value($row);
            $row->_inflated_attributes->{ $fk->name }++;
        }
    }
    $self->set_cache( \@objects );
    return $self;
}

sub order_by {
    my ( $self, $order ) = @_;
    return $self unless $order;
    my $current = $self->{attrs}->{order_by};
    $current = [$current]
        if ( ref $current eq 'HASH'
        || ref $current eq 'SCALAR'
        || !ref $current );
    $self->throw_exception(
        'Cannot handle order_by clause of type ' . ref $current )
        unless ( ref $current eq 'ARRAY' );
    unshift( @{$current}, ( ref $order eq 'ARRAY' ? @{$order} : $order ) );
    return $self->search( undef, { order_by => $current } );
}

sub hri {
    shift->search( undef,
        { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );
}

{
    no strict 'refs';
    foreach my $attr (
        qw(offset rows page columns prefetch where having group_by join select as)
        )
    {
        *{$attr} = sub {
            my $self = shift;
            $self->search( undef, { $attr => @_ > 1 ? [@_] : @_ } );
            }
    }

    foreach my $attr (qw(cache distinct)) {
        *{$attr} = sub {
            my $self = shift;
            $self->search( undef, { $attr => defined $_[0] ? $_[0] : 1 } );
            }
    }
}

sub for_update {
    shift->search( undef, { for => 'update' } );
}

sub for_shared {
    shift->search( undef, { for => 'shared' } );
}
1;
