package # hide from PAUSE 
    DBICTest::Schema::Track;

use MooseX::DBIC; with 'DBICTest::Compat';

# load_components(qw/InflateColumn::DateTime Ordered/);

remove 'id';

has_column trackid => ( isa => 'Int', auto_increment => 1, primary_key => 1 );

has_column position => ( isa => 'Int', accessor => 'pos' );
has_column title => ( size => 100 );

has_column [qw(last_updated_at last_updated_on)] => (isa => 'DateTime',
    accessor => 'updated_date',
  );

has_column small_dt => ( isa => 'DateTime', # for mssql and sybase DT tests
    data_type => 'smalldatetime');

#__PACKAGE__->position_column ('position');
#__PACKAGE__->grouping_column ('cd');


belongs_to cd => ( isa => 'DBICTest::Schema::CD' );
# belongs_to( disc => 'DBICTest::Schema::CD', foreign_key => 'cd');

might_have cd_single => ( isa => 'DBICTest::Schema::CD', foreign_key => 'single_track' );
might_have lyrics => ( isa => 'DBICTest::Schema::Lyrics', foreign_key => 'track' );

#belongs_to year1999cd => ( isa => "DBICTest::Schema::Year1999CDs", join_type => 'left', foreign_key => 'cd' );
#belongs_to year2000cd => ( isa => "DBICTest::Schema::Year2000CDs", join_type => 'left', foreign_key => 'cd' );

1;
