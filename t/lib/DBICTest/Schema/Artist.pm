package # hide from PAUSE 
    DBICTest::Schema::Artist;

use MooseX::DBIC; with 'DBICTest::Compat';

# __PACKAGE__->source_info({
#     "source_info_key_A" => "source_info_value_A",
#     "source_info_key_B" => "source_info_value_B",
#     "source_info_key_C" => "source_info_value_C",
# });

remove 'id';

has_column artistid => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

has_column name => ( size => 100, trigger => \&_set_name );
has_column rank => ( isa => 'Int', default => 13, required => 1 );
has_column charfield => ( size => 10 );
# 
# __PACKAGE__->mk_classdata('field_name_for', {
#     artistid    => 'primary key',
#     name        => 'artist name',
# });

has_many cds => ( isa => ResultSet['DBICTest::Schema::CD'], cascade_delete => 1 );
#    { order_by => 'year' },

has_many cds_unordered => ( isa => ResultSet['DBICTest::Schema::CD'] );
has_many cds_very_very_very_long_relationship_name => ( isa => ResultSet['DBICTest::Schema::CD'] );

#__PACKAGE__->has_many( twokeys => 'DBICTest::Schema::TwoKeys' );
#__PACKAGE__->has_many( onekeys => 'DBICTest::Schema::OneKey' );

has_many artist_undirected_maps => ( isa => ResultSet['DBICTest::Schema::ArtistUndirectedMap'] );
#  { cascade_copy => 0 } # this would *so* not make sense

has_many artwork_to_artist => ( isa => ResultSet['DBICTest::Schema::Artwork_to_Artist'] );

#__PACKAGE__->many_to_many('artworks', 'artwork_to_artist', 'artwork');


sub sqlt_deploy_hook {
  my ($self, $sqlt_table) = @_;

  if ($sqlt_table->schema->translator->producer_type =~ /SQLite$/ ) {
    $sqlt_table->add_index( name => 'artist_name_hookidx', fields => ['name'] )
      or die $sqlt_table->error;
  }
}

sub _set_name {
    my ($self, $new, $old) = @_;
    return unless($new =~ /(X )?store_column test/);
    $new = 'X '. $new;
    $self->meta->get_attribute('name')->set_raw_value($self, $new) if($new);
}

1;
