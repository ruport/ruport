require "test/unit"
require "ruport"
class TestSqlSplit < Test::Unit::TestCase
	include Ruport
	
	def test_sql_split1
		sql = File.read 'test/samples/ruport_test.sql'
		split = Query::SqlSplit.new sql
		assert_equal( 'SELECT * FROM ruport_test', split.last )
	end
	
	def test_sql_split2
		sql = "SELECT * FROM ruport_test"
		split = Query::SqlSplit.new sql
		assert_equal( 1, split.size )
		assert_equal( sql, split.first )
	end
end
