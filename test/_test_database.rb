require "test/unit"
require "ruport"

class TestSqlSplit < Test::Unit::TestCase
	def teardown
		FileUtils.rm '/tmp/compare.sql' if File.exist?( '/tmp/compare.sql' )
	end
	
	def test_stonecodeblog_sql
		user = 'test'
		password = 'password'
		dbh = DBI.connect( "dbi:Mysql:test:localhost", user, password )
		dbh.do 'drop database if exists stonecodeblog'
		orig_sql = 'test/samples/stonecodeblog.sql'
		sql = File.read orig_sql
		split = Ruport::Report::SqlSplit.new sql
		split.each do |sql| dbh.do( sql ); end
		tmp_sql = '/tmp/compare.sql'
		md_command =
			"mysqldump -u#{ user } -p#{ password } --databases stonecodeblog"
		`#{ md_command } > #{ tmp_sql }`
		diff = `diff #{ orig_sql } #{ tmp_sql }`
		assert( diff == '', diff[0..500] ) 
	end
end
