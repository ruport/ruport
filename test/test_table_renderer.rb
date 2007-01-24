require "test/unit"
require "ruport"

begin
  require "rubygems"
rescue LoadError
  nil
end

class TestTableRenderer < Test::Unit::TestCase
  def test_render_csv_basic
    actual = Ruport::Renderer::Table.render_csv { |r| 
      r.data = [[1,2,3],[4,5,6]].to_table 
    }
    assert_equal("1,2,3\n4,5,6\n",actual)

    actual = Ruport::Renderer::Table.render_csv { |r|
      r.data = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    }
    assert_equal("a,b,c\n1,2,3\n4,5,6\n",actual)
  end

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

  def test_render_latex_basic
    data = [[1,2,3,2],[3,4,5,6]].to_table(%w[a b c d])
    output = data.to_latex
    assert_equal "\\documentclass", output[/\\documentclass/]
    assert_equal "\\begin{document}", output[/\\begin\{document\}/]
    assert_equal "\\end{document}", output[/\\end\{document\}/]
  end

  def test_render_pdf_basic
    begin
      require "pdf/writer" 
    rescue LoadError 
      warn "skipping pdf test"; return
    end
   data = [[1,2],[3,4]].to_table
   assert_raise(RuntimeError) { data.to_pdf }

   data.column_names = %w[a b]
   assert_nothing_raised { data.to_pdf }
  end

  def test_prune
    actual = Ruport::Renderer::Table.render_csv { |r|
      r.data = [[1,2,3],[1,5,6]].to_table(%w[a b c])
      r.prune(1)
    }
    assert_equal("a,b,c\n1,2,3\n,5,6\n",actual)
  end

  def test_num_cols
    Ruport::Renderer::Table.render_csv { |r|
      r.data = [[1,2,3],[4,5,6]].to_table
      assert_equal 3, r.num_cols
    }
  end

  def test_rewrite_column
    actual = Ruport::Renderer::Table.render_csv { |r|
      r.data = [[1,2,3],[4,5,6]].to_table
      r.rewrite_column(0) { |r| r[0]+r[1] }
    }
    assert_equal("3,2,3\n9,5,6\n",actual)
  end

  def test_layout_header
    actual = Ruport::Renderer::Table.render_csv { |r|
      r.data = [[1,2,3],[4,5,6]].to_table(%w[a b c])
      r.layout { |l| l.show_table_headers = false }
    }
    assert_equal("1,2,3\n4,5,6\n",actual)
  end  
  
end
