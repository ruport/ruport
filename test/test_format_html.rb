require "test/unit"
require "ruport"

begin
  require "rubygems"
rescue LoadError
  nil
end

class TestFormatHTML < Test::Unit::TestCase
  def test_render_html_basic
    
    actual = Ruport::Renderer::Table.render_html { |r|
      r.data = [[1,2,3],[4,5,6]].to_table
    }          
    
    assert_equal("\t<table>\n\t\t<tr>\n\t\t\t<td>1</td>\n\t\t\t<td>2"+
                 "</td>\n\t\t\t<td>3</td>\n\t\t</tr>\n\t\t<tr>\n\t\t"+
                 "\t<td>4</td>\n\t\t\t<td>5</td>\n\t\t\t<td>6</td>\n\t"+
                 "\t</tr>\n\t</table>",actual)

    actual = Ruport::Renderer::Table.render_html { |r| 
      r.data = [ [1,2,3],[4,5,6]].to_table(%w[a b c]) 
    }
    
    assert_equal("\t<table>\n\t\t<tr>\n\t\t\t<th>a</th>\n\t\t\t<th>b</th>"+
      "\n\t\t\t<th>c</th>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>1</td>"+
      "\n\t\t\t<td>2</td>\n\t\t\t<td>3</td>\n\t\t</tr>\n\t\t<tr>"+
      "\n\t\t\t<td>4</td>\n\t\t\t<td>5</td>\n\t\t\t<td>6</td>\n\t"+
      "\t</tr>\n\t</table>",actual)   
    
  end

  def test_render_html_row
    actual = Ruport::Renderer::Row.render_html { |r| r.data = [1,2,3] }
    assert_equal("\t\t<tr>\n\t\t\t<td>1</td>\n\t\t\t<td>2"+
                 "</td>\n\t\t\t<td>3</td>\n\t\t</tr>\n",actual)
  end
    
  def test_render_html_with_tags 
    actual = Ruport::Renderer::Table.render_html { |r| 
      r.data = [[1,2,3],[4,5,6]].to_table(%w[a b c])
      r.data.create_group("foo") { |r| r.a < 3 }
    } 
    
    expected =
    "\t<table>\n\t\t<tr>\n\t\t\t<th>a</th>\n\t\t\t<th>b</th>\n\t\t\t<th>"+
    "c</th>\n\t\t</tr>\n\t\t<tr class='grp_foo'>\n\t\t\t"+
    "<td class='grp_foo'>1</td>\n\t\t\t<td class='grp_foo'>2</td>"+
    "\n\t\t\t<td class='grp_foo'>3</td>\n\t\t</tr>"+
    "\n\t\t<tr>\n\t\t\t<td>4</td>\n\t\t\t<td>5</td>\n\t\t\t"+
    "<td>6</td>\n\t\t</tr>\n\t</table>"             
    
    assert_equal(expected,actual) 
  end      

  def test_render_html_row_with_tags
    actual = Ruport::Renderer::Row.render_html(:class_str => " class='foo'") { |r|
      r.data = [1,2,3]
    }
    assert_equal("\t\t<tr class='foo'>\n\t\t\t<td class='foo'>1</td>\n"+
                 "\t\t\t<td class='foo'>2</td>\n\t\t\t"+
                 "<td class='foo'>3</td>\n\t\t</tr>\n",actual)
  end
  
  def test_ensure_html_tags_joined
    actual = Ruport::Renderer::Table.render_html { |r|
      r.data =[[1,2],[3,4]].to_table(%w[a b])
      r.data.create_group("foo") { true }
      r.data.create_group("bar") { true }
    }     
    
    expected =  
    "\t<table>\n"+
    "\t\t<tr>\n" +
    "\t\t\t<th>a</th>\n"  +
    "\t\t\t<th>b</th>\n" +
    "\t\t</tr>\n" +
    "\t\t<tr class='grp_foo grp_bar'>\n" +
    "\t\t\t<td class='grp_foo grp_bar'>1</td>\n" +
    "\t\t\t<td class='grp_foo grp_bar'>2</td>\n" +
    "\t\t</tr>\n" +
    "\t\t<tr class='grp_foo grp_bar'>\n"+
    "\t\t\t<td class='grp_foo grp_bar'>3</td>\n"+
    "\t\t\t<td class='grp_foo grp_bar'>4</td>\n"+
    "\t\t</tr>\n"+
    "\t</table>"
    
    assert_equal(expected,actual)
  end
end
