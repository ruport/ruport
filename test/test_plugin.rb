require "test/unit"
require "ruport"


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

  plugin_name :tsv
  register_on Format::Engine::Table
  
end

class CSVPluginTest < Test::Unit::TestCase

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

class PDFPluginTest < Test::Unit::TestCase

  def test_ensure_fails_on_array
    a = Format.table_object :plugin => :pdf, :data => [[1,2],[3,4]]
    assert_raise(RuntimeError) { a.render }
    
    a.data = a.data.to_table(:column_names => %w[a b])
    assert_nothing_raised { a.render }
    
    #FIXME: Engine should be further duck typed so this test will pass
    #a.data = [{ "a" => "b", "c" => "d" },{"a" => "f", "c" => "g"}]
    #assert_nothing_raised { a.render } 
  end

  def test_hooks
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

class HTMLPluginTest < Test::Unit::TestCase

  def test_basic
    a = Format.table_object :plugin => :html, :data => [[1,2],[3,nil]]
    assert_equal("<table>\n\t\t<tr>\n\t\t\t<td>1</td>\n\t\t\t<td>2</td>"+
                 "\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>3</td>\n\t\t\t<td>&nbsp;"+
                 "</td>\n\t\t</tr>\n\t</table>",a.render)
    a.data = a.data.to_table(:column_names => %w[a b])
    assert_equal("<table>\n\t\t<tr>\n\t\t\t<th>a </th>\n\t\t\t<th>b</th>"+
                 "\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>1</td>\n\t\t\t<td>"+
                 "2</td>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>3</td>\n\t\t\t<td>"+
                 "&nbsp;</td>\n\t\t</tr>\n\t</table>",a.render)
    a.show_field_names = false
    assert_equal("<table>\n\t\t<tr>\n\t\t\t<td>1</td>\n\t\t\t<td>2</td>"+
                 "\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>3</td>\n\t\t\t<td>&nbsp;"+
                 "</td>\n\t\t</tr>\n\t</table>",a.render)
  end
end

  
#this test is intended to ensure proper functionality of the plugin system.
class NewPluginTest < Test::Unit::TestCase
    
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
    assert_equal(3,a.active_plugin.max_col_width(0))
    assert_equal(1,a.active_plugin.max_col_width(1))

    a.data = [[1,2],[300,4]].to_table(:column_names => %w[a b])

    assert_equal(3,a.active_plugin.max_col_width("a"))
    assert_equal(1,a.active_plugin.max_col_width("b"))
    assert_equal(3,a.active_plugin.max_col_width(0))

    a.data = [[1,2],[3,40000]].to_table(:column_names => %w[foo bazz])
    assert_equal(3,a.active_plugin.max_col_width("foo"))
    assert_equal(5,a.active_plugin.max_col_width("bazz"))

    assert_equal(3,a.active_plugin.max_col_width(0))
    assert_equal(5,a.active_plugin.max_col_width(1))  
  end

  def test_table_width
    a = Format.table_object :plugin => :text, :data => [[1,2],[300,4]]
    assert_equal(4,a.active_plugin.table_width)
    
    a.data = [[1,2],[3,40000]].to_table(:column_names =>%w[foo bazz])
    assert_equal(8,a.active_plugin.table_width)
  end

  def test_hr
    a = Format.table_object :plugin => :text, :data => [[1,2],[300,4]]
    
    assert_equal("+---------+\n",a.active_plugin.hr)


    a.data = [[1,2],[3,40000]].to_table(:column_names => %w[foo bazz])
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
  
end

