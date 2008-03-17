#!/usr/bin/env ruby -w  
require File.join(File.expand_path(File.dirname(__FILE__)), "helpers")

class TestRenderHTMLTable < Test::Unit::TestCase
  
  def setup
    Ruport::Formatter::Template.create(:simple) do |format|
      format.table = {
        :show_headings  => false
      }
      format.grouping = {
        :style          => :justified,
        :show_headings  => false
      }
    end
  end
  
  def test_html_table
    a = Ruport::Formatter::HTML.new

    actual = a.html_table { "<tr><td>1</td></tr>\n" }
    assert_equal "<table>\n<tr><td>1</td></tr>\n</table>\n", actual
  end

  def test_render_html_basic
    
    actual = Ruport::Controller::Table.render_html { |r|
      r.data = Table([], :data => [[1,2,3],[4,5,6]])
    }          
    
    assert_equal("\t<table>\n\t\t<tr>\n\t\t\t<td>1</td>\n\t\t\t<td>2"+
                 "</td>\n\t\t\t<td>3</td>\n\t\t</tr>\n\t\t<tr>\n\t\t"+
                 "\t<td>4</td>\n\t\t\t<td>5</td>\n\t\t\t<td>6</td>\n\t"+
                 "\t</tr>\n\t</table>\n",actual)

    actual = Ruport::Controller::Table.render_html { |r| 
      r.data = Table(%w[a b c], :data => [ [1,2,3],[4,5,6]]) 
    }
    
    assert_equal("\t<table>\n\t\t<tr>\n\t\t\t<th>a</th>\n\t\t\t<th>b</th>"+
      "\n\t\t\t<th>c</th>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>1</td>"+
      "\n\t\t\t<td>2</td>\n\t\t\t<td>3</td>\n\t\t</tr>\n\t\t<tr>"+
      "\n\t\t\t<td>4</td>\n\t\t\t<td>5</td>\n\t\t\t<td>6</td>\n\t"+
      "\t</tr>\n\t</table>\n",actual)   
    
  end
  
  def test_render_with_template
    formatter = Ruport::Formatter::HTML.new
    formatter.options = Ruport::Controller::Options.new
    formatter.options.template = :simple
    formatter.apply_template
    
    assert_equal false, formatter.options.show_table_headers

    assert_equal :justified, formatter.options.style
    assert_equal false, formatter.options.show_group_headers
  end

  def test_options_hashes_override_template
    opts = nil
    table = Table(%w[a b c])
    table.to_html(
      :template => :simple,
      :table_format => {
        :show_headings  => true
      },
      :grouping_format => {
        :style => :inline,
        :show_headings  => true
      }
    ) do |r|
      opts = r.options
    end
    
    assert_equal true, opts.show_table_headers

    assert_equal :inline, opts.style
    assert_equal true, opts.show_group_headers
  end

  def test_individual_options_override_template
    opts = nil
    table = Table(%w[a b c])
    table.to_html(
      :template => :simple,
      :show_table_headers => true,
      :style => :inline,
      :show_group_headers => true
    ) do |r|
      opts = r.options
    end
    
    assert_equal true, opts.show_table_headers

    assert_equal :inline, opts.style
    assert_equal true, opts.show_group_headers
  end
end
   

class TestRenderHTMLRow < Test::Unit::TestCase
  
  def test_render_html_row
    actual = Ruport::Controller::Row.render_html { |r| r.data = [1,2,3] }
    assert_equal("\t\t<tr>\n\t\t\t<td>1</td>\n\t\t\t<td>2"+
                 "</td>\n\t\t\t<td>3</td>\n\t\t</tr>\n",actual)
  end
end
   

class TestRenderHTMLGroup < Test::Unit::TestCase
    
  def test_render_html_group
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [[1,2,3],[4,5,6]],
                                    :column_names => %w[a b c])
    actual = Ruport::Controller::Group.render(:html, :data => group)
    assert_equal "\t<p>test</p>\n"+
      "\t<table>\n\t\t<tr>\n\t\t\t<th>a</th>\n\t\t\t<th>b</th>"+
      "\n\t\t\t<th>c</th>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>1</td>"+
      "\n\t\t\t<td>2</td>\n\t\t\t<td>3</td>\n\t\t</tr>\n\t\t<tr>"+
      "\n\t\t\t<td>4</td>\n\t\t\t<td>5</td>\n\t\t\t<td>6</td>\n\t"+
      "\t</tr>\n\t</table>\n", actual
  end

  def test_render_html_group_without_headers
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [[1,2,3],[4,5,6]],
                                    :column_names => %w[a b c])
    actual = Ruport::Controller::Group.render(:html, :data => group,
      :show_table_headers => false)
    assert_equal "\t<p>test</p>\n\t<table>\n\t\t<tr>\n\t\t\t<td>1</td>"+
      "\n\t\t\t<td>2</td>\n\t\t\t<td>3</td>\n\t\t</tr>\n\t\t<tr>"+
      "\n\t\t\t<td>4</td>\n\t\t\t<td>5</td>\n\t\t\t<td>6</td>\n\t"+
      "\t</tr>\n\t</table>\n", actual
  end                                           
end


class TestRenderHTMLGrouping < Test::Unit::TestCase

  def test_render_html_grouping
    table = Table(%w[a b c]) << [1,2,3] << [1,1,3] << [2,7,9]
    g = Grouping(table,:by => "a")
    actual = Ruport::Controller::Grouping.render(:html, :data => g,
                                               :show_table_headers => false)

    assert_equal "\t<p>1</p>\n\t<table>\n\t\t<tr>\n\t\t\t<td>2</td>\n"+
    "\t\t\t<td>3</td>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>1</td>\n\t\t\t"+
    "<td>3</td>\n\t\t</tr>\n\t</table>\n\n\t<p>2</p>\n\t<table>\n\t\t<tr>"+
    "\n\t\t\t<td>7</td>\n\t\t\t<td>9</td>\n\t\t</tr>\n\t</table>\n\n", actual
  end

  def test_render_html_grouping_with_table_headers
    table = Table(%w[a b c]) << [1,2,3] << [1,1,3] << [2,7,9]
    g = Grouping(table,:by => "a")
    actual = Ruport::Controller::Grouping.render(:html, :data => g)

    assert_equal "\t<p>1</p>\n\t<table>\n\t\t<tr>\n\t\t\t<th>b</th>\n"+
                 "\t\t\t<th>c</th>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>"+
                 "2</td>\n\t\t\t<td>3</td>\n\t\t</tr>\n\t\t<tr>\n\t\t"+
                 "\t<td>1</td>\n\t\t\t<td>3</td>\n\t\t</tr>\n\t</table>\n\n"+
                 "\t<p>2</p>\n\t<table>\n\t\t<tr>\n\t\t\t<th>b</th>\n\t\t"+
                 "\t<th>c</th>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>7</td>\n"+
                 "\t\t\t<td>9</td>\n\t\t</tr>\n\t</table>\n\n", actual
  end

  def test_render_justified_html_grouping
    table = Table(%w[a b c]) << [1,2,3] << [1,1,3] << [2,7,9]
    g = Grouping(table,:by => "a")
    actual = Ruport::Controller::Grouping.render(:html, :data => g,
                                               :style => :justified)

    assert_equal "\t<table>\n\t\t<tr>\n\t\t\t<th>a</th>\n\t\t\t<th>b</th>\n"+
                 "\t\t\t<th>c</th>\n\t\t</tr>\n\t\t<tr>\n\t\t\t"+
                 "<td class=\"groupName\">1</td>\n\t\t\t<td>"+
                 "2</td>\n\t\t\t<td>3</td>\n\t\t</tr>\n\t\t<tr>\n\t\t\t"+
                 "<td>&nbsp;</td>\n\t\t\t<td>1</td>\n\t\t\t<td>3</td>"+
                 "\n\t\t</tr>\n\t\t<tr>\n\t\t\t"+
                 "<td class=\"groupName\">2</td>\n\t\t\t<td>7</td>\n"+
                 "\t\t\t<td>9</td>\n\t\t</tr>\n\t</table>\n", actual
  end
end  
     

class TestHTMLFormatterHelpers < Test::Unit::TestCase
  begin
    require "rubygems"
  rescue LoadError
    nil
  end
  
  def test_textile     
    require "redcloth"
    a = Ruport::Formatter::HTML.new
    assert_equal "<p><strong>foo</strong></p>", a.textile("*foo*")
  rescue LoadError
    STDERR.puts "Skipping textile test... needs redcloth"
  end
end
