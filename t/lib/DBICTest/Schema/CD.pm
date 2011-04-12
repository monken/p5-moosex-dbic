package # hide from PAUSE 
    DBICTest::Schema::CD;

use Moose;
use MooseX::DBIC; with 'DBICTest::Compat';


remove 'id';

has_column cdid => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

has_column [qw(title year)];

belongs_to artist => ( isa => 'DBICTest::Schema::Artist' );# { is_deferrable => 1, });

# in case this is a single-cd it promotes a track from another cd
belongs_to single_track => ( isa => 'DBICTest::Schema::Track', join_type => 'LEFT' );

has_many tracks => ( isa => ResultSet['DBICTest::Schema::Track'], cascade_delete => 1 );
has_many tags => ( isa => ResultSet['DBICTest::Schema::Tag'], #order_by => 'tag' 
);
has_many cd_to_producer => ( isa => ResultSet['DBICTest::Schema::CD_to_Producer'], cascade_delete => 1 );

might_have liner_notes => ( isa => 'DBICTest::Schema::LinerNotes', handles => [ qw/notes/ ] );

might_have artwork => ( isa => 'DBICTest::Schema::Artwork', foreign_key => 'cd' );
might_have mandatory_artwork => ( isa => 'DBICTest::Schema::Artwork' );

# many_to_many( producers => cd_to_producer => 'producer' );
# many_to_many(
    # producers_sorted => cd_to_producer => 'producer',
    # { order_by => 'producer.name' },
# );

belongs_to genre => ( isa => 'DBICTest::Schema::Genre',
        join_type => 'left',
        #on_delete => 'SET NULL',
        #on_update => 'CASCADE',
);

#This second relationship was added to test the short-circuiting of pointless
#queries provided by undef_on_null_fk. the relevant test in 66relationship.t
belongs_to genre_inefficient => ( isa => 'DBICTest::Schema::Genre',
        join_type => 'left',
        #on_delete => 'SET NULL',
        #on_update => 'CASCADE',
        #undef_on_null_fk => 0,
    
);

sub add_to_producers {
    shift->create_related('cd_to_producer', { producer => shift });
}

sub producers {
    shift->search_related('cd_to_producer')->search_related('producer');
}

1;
