package MooseX::DBIC::Role::Audit;

use Moose::Role;
use MooseX::DBIC;

has_column revision => ( isa => 'Int', default => 0, required => 1 );
belongs_to current => ( isa => sub { shift->name } );
has_many versions => (
    isa         => sub { shift->name },
    foreign_key => 'current',
    builder     => '_build_versions'
);

sub _build_versions {
    my $self = shift;
    my $rs   = $self->related_resultset('versions')->search(undef, { order_by => { -desc => 'revision' } });
    $rs->{attrs}->{where} =
      { $rs->current_source_alias . '.current' => $self->id };
    return $rs;
}

around update => sub {
    my ( $orig, $self, $upd ) = @_;
    return unless ( $self->in_storage );
    my %dirty = $self->get_dirty_columns;
    return $self->$orig($upd) unless ( $upd || keys %dirty );
    $upd ||= {};
    my $scope = $self->result_source->schema->txn_scope_guard;
    my %data = ( %{ $self->{_raw_data} }, current => $self->id );
    delete $data{id};
    $self->result_source->resultset->create( \%data );
    $self->$orig( { %$upd, revision => $self->revision + 1 } );
    $scope->commit;
    return $self;
};

1;
