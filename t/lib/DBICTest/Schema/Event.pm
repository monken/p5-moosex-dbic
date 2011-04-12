package DBICTest::Schema::Event;

use Moose;
use MooseX::DBIC; with 'DBICTest::Compat';

has_column id => ( isa => 'Int', auto_increment => 1 );
has_column starts_at => ( isa => 'DateTime' );
has_column created_on => ( isa => 'DateTime' );
has_column varchar_date => ( isa => 'DateTime' );
has_column varchar_datetime => ( isa => 'DateTime' );
has_column skip_inflation => ( isa => 'DateTime' );
has_column ts_without_tz => ( isa => 'DateTime' );

1;
