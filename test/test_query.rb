 require "test/unit"
 require "ruport"
 
 begin
   require 'mocha'
   require 'stubba'
   require 'dbi'
 rescue LoadError
   $stderr.puts "Warning: Mocha not found -- skipping some Query tests"
 end
   
 class TestQuery < Test::Unit::TestCase
   def setup
     @sources = {
       :default => {
         :dsn => 'ruport:test',  :user => 'greg',   :password => 'apple' },
       :alternative => {
         :dsn => "ruport:test2", :user => "sandal", :password => "harmonix" },
     }
     Ruport::Config.source :default,     @sources[:default]
     Ruport::Config.source :alternative, @sources[:alternative]
 
     @columns = %w(a b c)
     @data = [ [[1,2,3],[4,5,6],[7,8,9]],
               [[9,8,7],[6,5,4],[3,2,1]],
               [[7,8,9],[4,5,6],[1,2,3]], ]
     @datasets = @data.dup
 
     @sql = [ "select * from foo", "create table foo ..." ]
     @sql << @sql.values_at(0, 0).join(";\n")
     @sql << @sql.values_at(1, 0).join(";\n")
     @query = {
      :plain      => Ruport::Query.new(@sql[0]),
      :sourced    => Ruport::Query.new(@sql[0], :source        => :alternative),
      :paramed    => Ruport::Query.new(@sql[0], :params        => [ 42 ]),
      :cached     => Ruport::Query.new(@sql[0], :cache_enabled => true),
      :uncached   => Ruport::Query.new(@sql[0], :cache_enabled => false),
      :precached  => Ruport::Query.new(@sql[0], :cache_enabled => true),
      :raw        => Ruport::Query.new(@sql[0], :raw_data      => true),
      :unraw      => Ruport::Query.new(@sql[0], :raw_data      => false),
      :resultless => Ruport::Query.new(@sql[1]),
      :multi      => Ruport::Query.new(@sql[2]),
      :mixed      => Ruport::Query.new(@sql[3]),
     }
     @query[:precached].cached_data = @data[0]
   end
 
   def test_execute
     return unless Object.const_defined? :Mocha
     query = @query[:uncached]
     setup_mock_dbi(1)
 
     assert_equal nil, query.execute
   end
 
   def test_execute_sourced
     return unless Object.const_defined? :Mocha
     query = @query[:sourced]
     setup_mock_dbi(1, :source => :alternative)
 
     assert_equal nil, query.execute
   end
 
   def test_execute_paramed
     return unless Object.const_defined? :Mocha
     query = @query[:paramed]
     setup_mock_dbi(1, :params => [ 42 ])
 
     assert_equal nil, query.execute
   end
 
   def test_result_cache_disabled
     return unless Object.const_defined? :Mocha
     query = @query[:uncached]
     setup_mock_dbi(3)
     
     assert_nothing_raised { query.result }
     assert_equal @data[1], get_raw(query.result)
     assert_equal @data[2], get_raw(query.result)
   end
   
   def test_result_cache_enabled
     return unless Object.const_defined? :Mocha
     query = @query[:cached]
     setup_mock_dbi(1)
     
     assert_nothing_raised { query.result }
     assert_equal @data[0], get_raw(query.result)
     assert_equal @data[0], get_raw(query.result)
   end
 
   def test_result_resultless
     return unless Object.const_defined? :Mocha
     query = @query[:resultless]
     setup_mock_dbi(1, :resultless => true, :sql => @sql[1])
 
     assert_equal nil, query.result
   end
 
   def test_result_multi
     return unless Object.const_defined? :Mocha
     query = @query[:multi]
     setup_mock_dbi(2)
 
     assert_equal @data[1], get_raw(query.result)
   end
 
   def test_result_raw_disabled
     return unless Object.const_defined? :Mocha
     query = @query[:unraw]
     setup_mock_dbi(1)
     
     assert_equal @data[0].to_table(@columns), query.result
   end  
 
   def test_result_raw_enabled
     return unless Object.const_defined? :Mocha
     query = @query[:raw]
     setup_mock_dbi(1)
     
     assert_equal @data[0], query.result
   end  
 
   def test_update_cache
     return unless Object.const_defined? :Mocha
     query = @query[:cached]
     setup_mock_dbi(2)
     
     assert_equal @data[0], get_raw(query.result)
     query.update_cache
     assert_equal @data[1], get_raw(query.cached_data)
     assert_equal @data[1], get_raw(query.result)
   end
 
   def test_clear_cache
     return unless Object.const_defined? :Mocha
     query = @query[:cached]
     setup_mock_dbi(2)
 
     assert_equal @data[0], get_raw(query.result)
     query.clear_cache
     assert_equal nil,      query.cached_data
     assert_equal @data[1], get_raw(query.result)
   end
   
   def test_disable_caching
     return unless Object.const_defined? :Mocha
     query = @query[:cached]
     setup_mock_dbi(3)
 
     assert_equal @data[0], get_raw(query.result)
     assert_equal @data[0], get_raw(query.result)
     query.disable_caching
     assert_equal @data[1], get_raw(query.result)
     assert_equal @data[2], get_raw(query.result)    
   end
 
   def test_enable_caching
     return unless Object.const_defined? :Mocha
     query = @query[:uncached]
     setup_mock_dbi(3)
 
     assert_equal @data[0], get_raw(query.result)
     assert_equal @data[1], get_raw(query.result)
     query.enable_caching
     assert_equal @data[2], get_raw(query.result)
     assert_equal @data[2], get_raw(query.result)    
   end
 
   def test_load_file
     return unless Object.const_defined? :Mocha
     File.expects(:read).
       with("query_test.sql").
       returns("select * from foo\n")
     
     query = Ruport::Query.new "query_test.sql"
     assert_equal "select * from foo", query.sql
   end
 
   def test_load_file_erb
     return unless Object.const_defined? :Mocha
     @table = 'bar'
     File.expects(:read).
       with("query_test.sql").
       returns("select * from <%= @table %>\n")
     
     query = Ruport::Query.new "query_test.sql", :binding => binding
     assert_equal "select * from bar", query.sql
   end
 
   def test_load_file_not_found
     return unless Object.const_defined? :Mocha
     File.expects(:read).
       with("query_test.sql").
       raises(Errno::ENOENT)
     Ruport.expects(:log).
       with("Could not open query_test.sql",
            :status => :fatal, :exception => LoadError).
       raises(LoadError)
 
     assert_raises LoadError do
       query = Ruport::Query.new "query_test.sql"
     end
   end
 
   def test_each_cache_disabled
     return unless Object.const_defined? :Mocha
     query = @query[:uncached]
     setup_mock_dbi(2)
 
     result = []; query.each { |r| result << r.to_a }
     assert_equal @data[0], result
                  
     result = []; query.each { |r| result << r.to_a }
     assert_equal @data[1], result
   end  
   
   def test_each_cache_enabled
     return unless Object.const_defined? :Mocha
     query = @query[:cached]
     setup_mock_dbi(1)
     
     result = []; query.each { |r| result << r.to_a }
     assert_equal @data[0], result
                  
     result = []; query.each { |r| result << r.to_a }
     assert_equal @data[0], result
   end  
 
   def test_each_multi
     return unless Object.const_defined? :Mocha
     query = @query[:multi]
     setup_mock_dbi(2)
 
     result = []; query.each { |r| result << r.to_a }
     assert_equal @data[1], result
   end
   
   def test_each_without_block
     assert_raise (LocalJumpError) { @query[:precached].each }
   end
   
   def test_select_source
     query = @query[:precached]
     assert_equal @sources[:default], get_query_source(query)
 
     query.select_source :alternative
     assert_equal @sources[:alternative], get_query_source(query)
   
     query.select_source :default
     assert_equal @sources[:default], get_query_source(query)
   end
 
   def test_initialize_source_temporary
     query = Ruport::Query.new "<unused>", @sources[:alternative]
     assert_equal @sources[:alternative], get_query_source(query)
   end
 
   def test_initialize_source_temporary_multiple
     query1 = Ruport::Query.new "<unused>", @sources[:default]
     query2 = Ruport::Query.new "<unused>", @sources[:alternative]
     
     assert_equal @sources[:default], get_query_source(query1)
     assert_equal @sources[:alternative], get_query_source(query2)
   end
 
   def test_generator
     query = @query[:precached]
     gen = query.generator
     assert_equal @data[0][0], gen.next 
     assert_equal @data[0][1], gen.next 
     assert_equal @data[0][2], gen.next 
     assert_raise(EOFError) { gen.next }
   end
 
   def test_to_table
     return unless Object.const_defined? :Mocha
     query = @query[:raw]
     setup_mock_dbi(3, :returns => @data[0])
 
     assert_equal @data[0], query.result
     assert_equal @data[0].to_table(@columns), query.to_table
     assert_equal @data[0], query.result
   end
 
   def test_to_csv
     return unless Object.const_defined? :Mocha
     query = @query[:plain]
     setup_mock_dbi(1)
     
     csv = @data[0].to_table(@columns).as(:csv)
     assert_equal csv, query.to_csv
   end
   
   private
   def setup_mock_dbi(count, options={})
     sql = options[:sql] || @sql[0]
     source = options[:source] || :default
     returns = options[:returns] || Proc.new { @datasets.shift }
     resultless = options[:resultless]
     params = options[:params] || []
     
     @dbh = mock("database_handle")
     @sth = mock("statement_handle")
     def @dbh.execute(*a, &b); execute__(*a, &b); ensure; sth__.finish if b; end
     def @sth.each; data__.each { |x| yield(x) }; end
     def @sth.fetch_all; data__; end
     
     DBI.expects(:connect).
       with(*@sources[source].values_at(:dsn, :user, :password)).
       yields(@dbh).times(count)
     @dbh.expects(:execute__).with(sql, *params).
       yields(@sth).returns(@sth).times(count)
     @dbh.stubs(:sth__).returns(@sth)
     @sth.expects(:finish).with().times(count)
     unless resultless
       @sth.stubs(:fetchable?).returns(true)
       @sth.stubs(:column_names).returns(@columns)
       @sth.expects(:data__).returns(returns).times(count)
     else
       @sth.stubs(:fetchable?).returns(false)
       @sth.stubs(:column_names).returns([])
       @sth.stubs(:cancel)
       @sth.expects(:data__).times(0)
     end  
   end
   
   def get_query_source(query)
     [ :dsn, :user, :password ].inject({}) do |memo, var|
       memo.update var => query.instance_variable_get("@#{var}")
     end
   end
 
   def get_raw(table)
     table.collect { |row| row.to_a }
   end

end
