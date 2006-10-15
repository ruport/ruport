require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end

include Ruport

# a sample plugin to test the system
class TSVPlugin < Format::Plugin

  require "fastercsv"
  
  format_field_names do
    FasterCSV.generate(:col_sep => "\t") { |csv| csv << data.column_names }
  end
  
  renderer :table do
    rendered_field_names +
    FasterCSV.generate(:col_sep => "\t") { |csv| data.each { |r| csv << r } }
  end

  helper(:foo, :engine => :table_engine) { }
  helper(:bar, :engines => [:table_engine,:invoice_engine]) { }
  helper(:baz) {}

  plugin_name :tsv
  register_on :table_engine

  # wont work, just for helper tests
  register_on :invoice_engine
  register_on :document_engine
  
  rendering_options :boring => :true
  
end

class NakedPlugin < Ruport::Format::Plugin
  plugin_name :naked
end


class TestPlugin < Test::Unit::TestCase
  def test_helper
    t = Ruport::Format.table_object :data => [[1,2]], :plugin => :tsv
    i = Ruport::Format.invoice_object :data => [[1,2]].to_table(%w[a b]), :plugin => :tsv
    d = Ruport::Format.document_object :data => "foo", :plugin => :tsv
    assert_nothing_raised { t.foo }
    assert_nothing_raised { t.bar }
    assert_nothing_raised { t.baz }
    assert_nothing_raised { i.bar }
    assert_nothing_raised { i.baz }
    assert_nothing_raised { d.baz }
    assert_raise(NoMethodError) { i.foo }
    assert_raise(NoMethodError) { d.foo }
    assert_raise(NoMethodError) { d.bar } 
  end

  def test_rendering_options
    t = Ruport::Format.table_object(:data => [[1,2]], :plugin => :tsv)
    assert t.active_plugin.respond_to?(:options)
    assert t.active_plugin.respond_to?(:rendering_options)
    assert t.active_plugin.rendering_options[:boring]
    assert_nil t.active_plugin.options
    assert_nil t.options
  end

  def test_register_on
     a = NakedPlugin.dup
     assert a.respond_to?(:register_on)
     assert_raise(InvalidPluginError) { 
       Ruport::Format.table_object(:plugin => :naked) 
     }
     assert_raise(InvalidPluginError) { 
       Ruport::Format.document_object(:plugin => :naked) 
     }
     a.register_on :table_engine, :document_engine
     assert_nothing_raised {
       Ruport::Format.table_object(:plugin => :naked) 
       Ruport::Format.document_object(:plugin => :naked) 
     }

  end

end

class TestCSVPlugin < Test::Unit::TestCase

  def test_basic
    a = Format.table_object :plugin => :csv, :data => [[1,2],[3,4]]
    assert_equal("1,2\n3,4\n",a.render)

    a.data = a.data.to_table(:column_names => %w[a b])
    assert_equal("a,b\n1,2\n3,4\n",a.render)

    a.data = Ruport::Data::Table.new :data => [[1,2],[3,4]]
    assert_equal("1,2\n3,4\n",a.render)

    a.data = Ruport::Data::Table.new :data => [[1,2],[3,4]], 
                                     :column_names => %w[a b]

    assert_equal("a,b\n1,2\n3,4\n",a.render)
    
    a.show_field_names = false
    assert_equal("1,2\n3,4\n", a.render)
  end

end

class TestPDFPlugin < Test::Unit::TestCase

  def test_ensure_fails_on_array
    begin
      require "pdf/writer" 
    rescue LoadError 
      warn "skipping pdf test"; return
    end
    a = Format.table_object :plugin => :pdf, :data => [[1,2],[3,4]]
    assert_raise(RuntimeError) { a.render }
    
    a.data = a.data.to_table(:column_names => %w[a b])
    assert_nothing_raised { a.render }
    
    #FIXME: Engine should be further duck typed so this test will pass
    #a.data = [{ "a" => "b", "c" => "d" },{"a" => "f", "c" => "g"}]
    #assert_nothing_raised { a.render } 
  end

  def test_hooks
    begin
      require "pdf/writer" 
    rescue LoadError 
      warn "skipping pdf test"; return
    end
    a = Format.table_object :plugin => :pdf, :data => [[1,2],[3,4]]
    a = Format.table_object :plugin => :pdf, 
          :data   => [[1,2],[3,4]].to_table(:column_names => %w[a b])
    y = 0
    a.active_plugin.pre  = lambda { |pdf| 
      assert_instance_of(PDF::Writer,pdf); 
      y = pdf.y
    }
    a.active_plugin.post = lambda { |pdf| 
      assert_instance_of(PDF::Writer,pdf); assert(pdf.y < y)
    }
    assert_nothing_raised { a.render } 
  end
  
end

class TestHTMLPlugin < Test::Unit::TestCase

  def test_basic
    a = Format.table_object :plugin => :html, :data => [[1,2],[3,nil]]
    assert_equal("\t<table>\n\t\t<tr>\n\t\t\t<td>1</td>\n\t\t\t<td>2</td>"+
                 "\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>3</td>\n\t\t\t<td>&nbsp;"+
                 "</td>\n\t\t</tr>\n\t</table>",a.render)
    a.data = a.data.to_table(:column_names => %w[a b])
    assert_equal("\t<table>\n\t\t<tr>\n\t\t\t<th>a</th>\n\t\t\t<th>b</th>"+
                 "\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>1</td>\n\t\t\t<td>"+
                 "2</td>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>3</td>\n\t\t\t<td>"+
                 "&nbsp;</td>\n\t\t</tr>\n\t</table>",a.render)
    a.show_field_names = false
    assert_equal("\t<table>\n\t\t<tr>\n\t\t\t<td>1</td>\n\t\t\t<td>2</td>"+
                 "\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>3</td>\n\t\t\t<td>&nbsp;"+
                 "</td>\n\t\t</tr>\n\t</table>",a.render)
    a.data[0].tag(:odd)
    a.data[1].tag(:even)
    assert_equal("\t<table>\n\t\t<tr class='odd'>\n\t\t\t<td class='odd'>"+
                 "1</td>\n\t\t\t<td class='odd'>2</td>\n\t\t</tr>\n\t\t"+
                 "<tr class='even'>\n\t\t\t<td class='even'>3</td>\n\t\t\t"+
                 "<td class='even'>&nbsp;</td>\n\t\t</tr>\n\t</table>",
                 a.render)
  end
end

  
#this test is intended to ensure proper functionality of the plugin system.
class TestNewPlugin < Test::Unit::TestCase
    
  def test_basic
    a = Format.table_object :plugin => :tsv, :data => [[1,2],[3,4]]
    assert_equal("1\t2\n3\t4\n",a.render)

    a.data = a.data.to_table(:column_names => %w[a b])
    assert_equal("a\tb\n1\t2\n3\t4\n",a.render)

    a.show_field_names = false
    assert_equal("1\t2\n3\t4\n",a.render)
  end

end

class TextPluginTest < Test::Unit::TestCase
  
  def test_basic

    tf = "+-------+\n"
    
    a = Format.table_object :plugin => :text, :data => [[1,2],[3,4]]
    assert_equal("#{tf}| 1 | 2 |\n| 3 | 4 |\n#{tf}",a.render)

    a.data = a.data.to_table(:column_names => %w[a b])
    assert_equal("#{tf}| a | b |\n#{tf}| 1 | 2 |\n| 3 | 4 |\n#{tf}", a.render)
    
  end

  def test_max_col_width
    a = Format.table_object :plugin => :text, :data => [[1,2],[300,4]]
    a.active_plugin.calculate_max_col_widths
    assert_equal(3,a.active_plugin.max_col_width[0])
    assert_equal(1,a.active_plugin.max_col_width[1])

    a.data = [[1,2],[300,4]].to_table(:column_names => %w[a ba])
    a.active_plugin.calculate_max_col_widths
    assert_equal(3,a.active_plugin.max_col_width[0])
    assert_equal(2,a.active_plugin.max_col_width[1])

    a.data = [[1,2],[3,40000]].to_table(:column_names => %w[foo bazz])
    a.active_plugin.calculate_max_col_widths
    assert_equal(3,a.active_plugin.max_col_width[0])
    assert_equal(5,a.active_plugin.max_col_width[1])  
  end

  def test_hr
    a = Format.table_object :plugin => :text, :data => [[1,2],[300,4]]
    a.active_plugin.calculate_max_col_widths
    assert_equal("+---------+\n",a.active_plugin.hr)


    a.data = [[1,2],[3,40000]].to_table(:column_names => %w[foo bazz])
    a.active_plugin.calculate_max_col_widths
    assert_equal "+-------------+\n", a.active_plugin.hr
    
  end

  def test_centering
    tf = "+---------+\n" 

    a = Format.table_object :plugin => :text, :data => [[1,2],[300,4]]
    assert_equal("#{tf}|  1  | 2 |\n| 300 | 4 |\n#{tf}",a.render)

    tf = "+------------+\n"
    a.data = a.data.to_table(:column_names => %w[a bark])
    assert_equal("#{tf}|  a  | bark |\n#{tf}|  1  |  2   |\n"+
                 "| 300 |  4   |\n#{tf}",a.render)
    
  end

  def test_wrapping
    
    a = Format.table_object :plugin => :text, :data => [[1,2],[300,4]]
   
    #def SystemExtensions.terminal_width; 10; end
    a.active_plugin.right_margin = 10
    assert_equal("+------->>\n|  1  | >>\n| 300 | >>\n+------->>\n",a.render)

    a = Format.table_object :plugin => :text, :data => [[1,2],[300,4]]
    assert_equal(nil,a.active_plugin.right_margin)
  end


  def test_make_sure_this_damn_column_names_bug_dies_a_horrible_death!
    a = Format.table :plugin => :text, :data => [[1,2,3]].to_table
    expected = "+-----------+\n"+
               "| 1 | 2 | 3 |\n"+
               "+-----------+\n"
    assert_equal(expected,a)

  end

  def test_graceful_failure_on_empty_table
    assert_nothing_raised { [].to_table.to_text }
    assert_nothing_raised { [].to_table(%w[a b c]).to_text }
  end

  
end

