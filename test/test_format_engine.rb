require 'ruport'
require 'rubygems' rescue LoadError nil
require 'test/unit'

class MockPlugin < Ruport::Format::Plugin
  
  renderer(:table) { "#{rendered_field_names}#{data}" }
 
  format_field_names { "#{data.column_names}" }
  
  renderer(:document) { data }

  rendering_options :red_cloth_enabled => true, 
                    :erb_enabled => true
  
  action(:reverse_data) { data.reverse }
  action(:mock_action)  { "mock" }

  helper(:test) { |eng| eng }

  attribute :apple

  helper(:complex_test) { |eng|
    eng.rewrite_column(0) { "a" } if apple 
  }

  plugin_name :mock
  register_on :table_engine
  register_on :document_engine

end

class TestTabularFormatEngine < Test::Unit::TestCase
  
  include Ruport
  
  def setup
    @engine = Format::Engine::Table.dup
  end

  def test_plugin_attributes
    assert_equal nil, @engine.active_plugin.apple
    @engine.active_plugin.apple = :banana
    assert_equal :banana, @engine.active_plugin.apple
  end
  def test_basic_render
     @engine.plugin = :mock
     @engine.data = [[1,2,3],[4,5,6],[7,8,9]]
     assert_equal( "#{@engine.data}", @engine.render )
  end

  def test_plugin_actions
    @engine.plugin = :mock
    @engine.data = [1,2,3,4]
    assert_equal( [4,3,2,1], @engine.active_plugin.reverse_data )
    assert_equal( "mock", @engine.active_plugin.mock_action )
  end

  def test_helper
    @engine.plugin = :mock
    assert_equal @engine, @engine.test
    @engine.data = [[1,2,3],[4,5,6]]
    @engine.complex_test
    assert_equal([[1,2,3],[4,5,6]],@engine.data)
    @engine.active_plugin.apple = true
    @engine.complex_test
    assert_equal([['a',2,3],['a',5,6]],@engine.data)
  end

  def test_render_without_field_names
    @engine.plugin = :mock
    @engine.show_field_names = false
    
    @engine.data = [[1,2,3],[4,5,6],[7,8,9]]
    assert_equal "#{@engine.data}", @engine.render 
  end

  # test that attempting to render using an invalid plugin returns an exception
  # with a useful message
  def test_render_with_invalid_plugin
    assert_raises(InvalidPluginError) {
      Format.table(:plugin => :monkeys, 
                   :data => [[1,2,3],[4,5,6],[7,8,9]].to_table(%w[a b c]))
    }
  end
  
  def test_simple_interface
    expected = "#{[[1,2],[3,4]]}"
    actual = Format.table(:plugin => :mock, :data => [[1,2],[3,4]]) 
    assert_equal(expected,actual)
  end

  def test_rewrite_column
    a = @engine.dup
    a.plugin = :mock
    
    a.data = [[1,2],[3,4]].to_table(:column_names =>%w[a b])
    a.rewrite_column("a") { |r| r["a"] + 1 }
    assert_equal([[2,2],[4,4]].to_table(:column_names => %w[a b]),a.data)
    assert_nothing_raised { a.render }
    
    a.data = [[5,6],[7,8]]
    a.rewrite_column(1) { "apple" }
    assert_equal [[5,"apple"],[7,"apple"]], a.data
    assert_nothing_raised { a.render }
  end

  def test_num_columns
    @engine.data = [[1,2,3,4],[5,6,7,8]]
    assert_equal(4,@engine.num_cols)

    @engine.data = [[1,2,3],[4,5,6]].to_table(:column_names => %w[a b c])
    assert_equal(3,@engine.num_cols)
  end

  def test_plugin_access
    @engine.plugin = :mock
    @engine.data   = [[1,5],[3,8]]

    #normal access
    assert_equal :mock, @engine.active_plugin.plugin_name
    assert_equal [[1,5],[3,8]], @engine.active_plugin.data

    #block access
    @engine.active_plugin do |p|
      assert_equal :mock, p.plugin_name
      assert_equal [[1,5],[3,8]], p.data
    end
  end

  def test_prune
    @engine.plugin = :mock
    @engine.data = [[1,2,3],[1,4,3],[2,4,1]]
    @engine.prune
    assert_equal([[1,2,3],[nil,4,3],[2,4,1]],@engine.data)
    @engine.data = [[1,2,3],[2,4,1],[2,7,9],[1,2,3],[1,7,9]]
    @engine.prune
    assert_equal([[1,2,3],[2,4,1],[nil,7,9],[1,2,3],[nil,7,9]],
                 @engine.data)
    @engine.data = [[1,2,3],[1,2,4],[1,3,7],[2,1,9],[2,2,3],[2,2,9]]
    @engine.prune
    assert_equal( [[1,2,3],[nil,nil,4],[nil,3,7],
                   [2,1,9],[nil,2,3],[nil,nil,9]], @engine.data)
     
    @engine.data = [[1,2,3],[1,2,4],[1,3,7],[2,1,9],[2,2,3],[2,2,9]]
    @engine.prune(1)
    assert_equal( [[1,2,3],[nil,2,4],[nil,3,7],
                   [2,1,9],[nil,2,3],[nil,2,9]], @engine.data)

    data = Ruport::Data::Table.new :column_names => %w[name date service amount]
    data << [ "Greg Gibson", "1/1/2000",  "Prophy",  "100.00" ] <<
            [ "Greg Gibson", "1/1/2000",  "Filling", "100.00" ] <<
            [ "Greg Gibson", "1/12/2000", "Prophy",  "100.00" ] <<
            [ "Greg Gibson", "1/12/2000", "Filling", "100.00" ] <<
            [ "Greg Brown",  "1/12/2000", "Prophy",  "100.00" ]

    @engine.data = data
    @engine.prune(1)
    data2 = data.dup
    data2[1][0] = data2[2][0] = data2[3][0] = nil
    assert_equal(data2, @engine.data)
    
    @engine.data=data

    data3 = data2.dup
    data3[1][1] = data3[3][1] = nil
    @engine.prune(2)

    assert_equal(data3, @engine.data)
  end

end

class TestDocumentFormatEngine < Test::Unit::TestCase
  
  include Ruport
  
  def setup
    @engine = Format::Engine::Document.dup
  end

  def test_basic_render
    @engine.plugin = :mock
    @engine.red_cloth_enabled = true
    @engine.erb_enabled = true
    @engine.data = "* <%= 3 + 2 %>\n* <%= 'apple'.reverse %>\n* <%= [1,2][0] %>"
    h = "<ul>\n\t<li>5</li>\n\t\t<li>elppa</li>\n\t\t<li>1</li>\n\t</ul>"
    assert_equal h, @engine.render
  end

  def test_simple_interface
   
   d = "*<%= 'apple'.reverse %>*"
   opts = { :data => d, :plugin => :mock }
   
   a = Format.document opts
   assert_equal "<p><strong>elppa</strong></p>", a
   
   a = Format.document opts.merge!({:red_cloth_enabled => false})
   assert_equal "*elppa*", a

   a = Format.document opts.merge!({:erb_enabled => false})
   assert_equal d, a

   a = Format.document :data => d, :plugin => :mock
   assert_equal "<p><strong>elppa</strong></p>", a
   
  end
end
  
  
