require "test/unit"
require "ruport"
class TestQuery < Test::Unit::TestCase
  
  
  def setup
    Ruport::Config.source :default,
      :dsn => "ruport:test", :user => "greg", :password => "apple"

    Ruport::Config.source :alternate,
      :dsn => "ruport:test2", :user => "sandal", :password => "harmonix"
    
    @query1 = Ruport::Query.new "select * from foo", :cache_enabled => true 
    @query1.cached_data = [[1,2,3],[4,5,6],[7,8,9]] 
  end
  
  
  def test_result
    assert_nothing_raised { @query1.result }
    assert_equal([[1,2,3],[4,5,6],[7,8,9]],@query1.result)
  end

  def test_auto_resolve_file
    q = Ruport::Query.new "test/samples/query_test.sql"
    assert_equal "select * from foo", q.sql
  end

  def test_erb_replacement
    @table = 'bar'
    q = Ruport::Query.new "test/samples/erb_test.sql", :binding => binding
    assert_equal "select * from bar", q.sql
  end

  def test_each
    data = [[1,2,3],[4,5,6],[7,8,9]]
    @query1.each do |r|
      assert_equal(data.shift,r)
    end
    data = [1,4,7]
    @query1.each do |r|
      assert_equal(data.shift,r.first)
    end
    assert_raise (LocalJumpError) { @query1.each }
  end

  def test_select_source
    
    assert_equal( "ruport:test", @query1.instance_eval("@dsn")  )
    assert_equal( "greg",        @query1.instance_eval("@user") )
    assert_equal( "apple",       @query1.instance_eval("@password") )

    @query1.select_source :alternate
  
    assert_equal( "ruport:test2", @query1.instance_eval("@dsn")  )
    assert_equal( "sandal",        @query1.instance_eval("@user") )
    assert_equal( "harmonix",       @query1.instance_eval("@password") ) 
    
    @query1.select_source :default

    assert_equal( "ruport:test", @query1.instance_eval("@dsn")  )
    assert_equal( "greg",        @query1.instance_eval("@user") )
    assert_equal( "apple",       @query1.instance_eval("@password") )
     
  end

  def test_generator
    assert @query1.generator.kind_of?(Generator)
    gen = @query1.generator
    assert_equal [1,2,3], gen.next 
    assert_equal [4,5,6], gen.next 
    assert_equal [7,8,9], gen.next 
    assert_raise(EOFError) { gen.next }
  end

  def test_caching_triggers
    assert_nothing_raised { @query1.enable_caching }
    assert_nothing_raised { @query1.disable_caching }
  end

end
