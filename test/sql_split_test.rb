require "test/helpers"
class TestSqlSplit < Test::Unit::TestCase
	include Ruport
 	
	def test_sql_split_trivial
		sql = "SELECT * FROM ruport_test"
		split = Query::SqlSplit.new sql
		assert_equal( 1, split.size )
		assert_equal( sql, split.first )
	end  
	
	def test_sql_split_complex
		sql = File.read 'test/samples/ruport_test.sql'
		split = Query::SqlSplit.new sql
		assert_equal( 'SELECT * FROM ruport_test', split.last )
	end
	
end
