package DBICTest::Schema::Genre;

use MooseX::DBIC; with 'DBICTest::Compat';

has_column name => ( size => 100 );

has_many cds => ( isa => ResultSet['DBICTest::Schema::CD'] );

has_one model_cd => ( isa => 'DBICTest::Schema::CD' );

1;
