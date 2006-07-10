begin require 'rubygems'; rescue LoadError; nil end
require 'ruport'
require 'test/unit'

class MockPlugin < Ruport::Format::Plugin
  
  renderer(:table) { "#{rendered_field_names}#{data}" }
 
  format_field_names { "#{data.fields}" }
  
  renderer(:document) { data }

  register_on :table_engine
  register_on :document_engine

  rendering_options :red_cloth_enabled => true, 
                    :erb_enabled => true

end

class TestTabularFormatEngine < Test::Unit::TestCase
  
  include Ruport
  
  def setup
    @engine = Format::Engine::Table.dup
  end
  
  def test_basic_render
     @engine.plugin = :mock
     @engine.data = [[1,2,3],[4,5,6],[7,8,9]]
     assert_equal( "#{@engine.data}", @engine.render )
  end

  def test_render_without_field_names
    @engine.plugin = :mock
    @engine.show_field_names = false
    
    @engine.data = [[1,2,3],[4,5,6],[7,8,9]]
    assert_equal "#{@engine.data}", @engine.render 
  end

  def test_simple_interface
    expected = "#{[[1,2],[3,4]]}"
    actual = Format.table(:plugin => :mock, :data => [[1,2],[3,4]]) 
    assert_equal(expected,actual)
  end

  def test_rewrite_column
    a = @engine.dup
    a.plugin = :mock
    
    a.data = [[1,2],[3,4]].to_ds(%w[a b])
    a.rewrite_column("a") { |r| r["a"] + 1 }
    assert_equal([[2,2],[4,4]].to_ds(%w[a b]),a.data)
    assert_nothing_raised { a.render }
    
    a.data = [[5,6],[7,8]]
    a.rewrite_column(1) { "apple" }
    assert_equal [[5,"apple"],[7,"apple"]], a.data
    assert_nothing_raised { a.render }
  end

  def test_num_columns
    @engine.data = [[1,2,3,4],[5,6,7,8]]
    assert_equal(4,@engine.num_cols)

    @engine.data = [[1,2,3],[4,5,6]].to_ds(%w[a b c])
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

end

class TestDocumentFormatEngine < Test::Unit::TestCase
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
  
  
