package # hide from PAUSE 
    DBICTest::Schema::CD;

use MooseX::DBIC; with 'DBICTest::Compat';

table 'cd';

has_column [qw(title year)];

belongs_to artist => ( isa => 'DBICTest::Schema::Artist' );# { is_deferrable => 1, });

# in case this is a single-cd it promotes a track from another cd
belongs_to single_track => ( isa => 'DBICTest::Schema::Track', join_type => 'LEFT' );

has_many tracks => ( isa => ResultSet['DBICTest::Schema::Track'] );
has_many tags => ( isa => ResultSet['DBICTest::Schema::Tag'], #order_by => 'tag' 
);
has_many cd_to_producer => ( isa => ResultSet['DBICTest::Schema::CD_to_Producer'] );

might_have liner_notes => ( isa => 'DBICTest::Schema::LinerNotes', handles => [ qw/notes/ ] );

might_have artwork => ( isa => 'DBICTest::Schema::Artwork' );
has_one mandatory_artwork => ( isa => 'DBICTest::Schema::Artwork' );

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

1;
