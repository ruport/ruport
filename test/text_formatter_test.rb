#!/usr/bin/env ruby -w
require File.join(File.expand_path(File.dirname(__FILE__)), "helpers")

class TestRenderTextTable < Test::Unit::TestCase 
  
  def setup
    Ruport::Formatter::Template.create(:simple) do |format|
      format.table = {
        :show_headings  => false,
        :width          => 50,
        :ignore_width   => true
      }
      format.column = {
        :maximum_width  => [5,5,7],
        :alignment => :center
      }
      format.grouping = {
        :show_headings  => false
      }
    end
  end

  def test_basic
    tf = "+-------+\n"
    
    a = Table([], :data => [[1,2],[3,4]]).to_text
    assert_equal("#{tf}| 1 | 2 |\n| 3 | 4 |\n#{tf}",a)

    a = Table(%w[a b], :data => [[1,2],[3,4]]).to_text
    assert_equal("#{tf}| a | b |\n#{tf}| 1 | 2 |\n| 3 | 4 |\n#{tf}", a)
  end
  
  def test_centering
    tf = "+---------+\n" 

    a = Table([], :data => [[1,2],[300,4]])
    assert_equal( "#{tf}|  1  | 2 |\n| 300 | 4 |\n#{tf}",
                  a.to_text(:alignment => :center) )

    tf = "+------------+\n"
    a.column_names = %w[a bark]     
    assert_equal("#{tf}|  a  | bark |\n#{tf}|  1  |  2   |\n"+
                 "| 300 |  4   |\n#{tf}", a.to_text(:alignment => :center) )   
  end

  def test_justified
    tf = "+----------+\n"
    a = Table([], :data => [[1,'Z'],[300,'BB']])
    
    # justified alignment can be set explicitly
    assert_equal "#{tf}|   1 | Z  |\n| 300 | BB |\n#{tf}", 
                 a.to_text(:alignment => :justified)    
    
    # justified alignment is also default             
    assert_equal "#{tf}|   1 | Z  |\n| 300 | BB |\n#{tf}", a.to_s      
  end

  def test_wrapping  
    a = Table([], :data => [[1,2],[300,4]]).to_text(:table_width => 10)
    assert_equal("+------->>\n|   1 | >>\n| 300 | >>\n+------->>\n",a)
  end  
  
  def test_ignore_wrapping
    a = Table([], :data => [[1,2],[300,4]]).to_text(:table_width => 10, 
                                         :ignore_table_width => true )
    assert_equal("+---------+\n|   1 | 2 |\n| 300 | 4 |\n+---------+\n",a)
  end 
  
  def test_render_empty_table
    assert_raise(Ruport::FormatterError) { Table([]).to_text }
    assert_nothing_raised { Table(%w[a b c]).to_text }

    a = Table(%w[a b c]).to_text
    expected = "+-----------+\n"+
               "| a | b | c |\n"+
               "+-----------+\n"
    assert_equal expected, a
  end
  
  def test_render_with_template
    formatter = Ruport::Formatter::Text.new
    formatter.options = Ruport::Controller::Options.new
    formatter.options.template = :simple
    formatter.apply_template
    
    assert_equal false, formatter.options.show_table_headers
    assert_equal 50, formatter.options.table_width
    assert_equal true, formatter.options.ignore_table_width

    assert_equal [5,5,7], formatter.options.max_col_width
    assert_equal :center, formatter.options.alignment

    assert_equal false, formatter.options.show_group_headers
  end
  
  def test_options_hashes_override_template
    opts = nil
    table = Table(%w[a b c])
    table.to_text(
      :template => :simple,
      :table_format => {
        :show_headings  => true,
        :width          => 25,
        :ignore_width   => false
      },
      :column_format => {
        :maximum_width  => [10,10,10],
        :alignment => :left
      },
      :grouping_format => {
        :show_headings  => true
      }
    ) do |r|
      opts = r.options
    end
    
    assert_equal true, opts.show_table_headers
    assert_equal 25, opts.table_width
    assert_equal false, opts.ignore_table_width

    assert_equal [10,10,10], opts.max_col_width
    assert_equal :left, opts.alignment

    assert_equal true, opts.show_group_headers
  end

  def test_individual_options_override_template
    opts = nil
    table = Table(%w[a b c])
    table.to_text(
      :template => :simple,
      :show_table_headers => true,
      :table_width => 75,
      :ignore_table_width => false,
      :max_col_width => [4,4,4],
      :alignment => :left,
      :show_group_headers => true
    ) do |r|
      opts = r.options
    end
    
    assert_equal true, opts.show_table_headers
    assert_equal 75, opts.table_width
    assert_equal false, opts.ignore_table_width

    assert_equal [4,4,4], opts.max_col_width
    assert_equal :left, opts.alignment

    assert_equal true, opts.show_group_headers
  end
                                             
  # -- BUG TRAPS ------------------------------

  def test_should_render_without_column_names
    a = Table([], :data => [[1,2,3]]).to_text
    expected = "+-----------+\n"+
               "| 1 | 2 | 3 |\n"+
               "+-----------+\n"
    assert_equal(expected,a)
  end
  
end
    

class TestRenderTextRow < Test::Unit::TestCase

  def test_row_basic
    actual = Ruport::Controller::Row.render_text(:data => [1,2,3])
    assert_equal("| 1 | 2 | 3 |\n", actual)
  end

end
        

class TestRenderTextGroup < Test::Unit::TestCase

  def test_render_text_group
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [ %w[is this more],
                                               %w[interesting red snapper]],
                                    :column_names => %w[i hope so])

    actual = Ruport::Controller::Group.render_text(:data => group)
    expected = "test:\n\n"+
               "+------------------------------+\n"+
               "|      i      | hope |   so    |\n"+
               "+------------------------------+\n"+
               "| is          | this | more    |\n"+
               "| interesting | red  | snapper |\n"+
               "+------------------------------+\n"
    assert_equal(expected, actual)
  end

  def test_render_text_group_without_headers
   group = Ruport::Data::Group.new(:name => 'test',
                                   :data => [ %w[is this more],
                                              %w[interesting red snapper]],
                                   :column_names => %w[i hope so])
   
    actual = Ruport::Controller::Group.render(:text, :data => group,
      :show_table_headers => false )
    expected = "test:\n\n"+
               "+------------------------------+\n"+
               "| is          | this | more    |\n"+
               "| interesting | red  | snapper |\n"+
               "+------------------------------+\n"
    assert_equal(expected, actual)
  end                                           
end       
       

class TestRenderTextGrouping < Test::Unit::TestCase

  def test_render_text_grouping
    table = Ruport::Data::Table.new(:data => [ %w[is this more],
                                               %w[interesting red snapper]],
                                    :column_names => %w[i hope so])
    grouping = Grouping(table, :by => "i")

    actual = Ruport::Controller::Grouping.render(:text, :data => grouping)
    expected = "interesting:\n\n"+
               "+----------------+\n"+
               "| hope |   so    |\n"+
               "+----------------+\n"+
               "| red  | snapper |\n"+
               "+----------------+\n\n"+
               "is:\n\n"+
               "+-------------+\n"+
               "| hope |  so  |\n"+
               "+-------------+\n"+
               "| this | more |\n"+
               "+-------------+\n\n"
    assert_equal(expected, actual)  
    
    actual = grouping.to_s
    assert_equal(expected,actual)
  end

  def test_render_text_grouping_without_headers
    table = Ruport::Data::Table.new(:data => [ %w[is this more],
                                               %w[interesting red snapper]],
                                    :column_names => %w[i hope so])
    grouping = Grouping(table, :by => "i")

    actual = Ruport::Controller::Grouping.render(:text, :data => grouping,
      :show_table_headers => false)
    expected = "interesting:\n\n"+
               "+----------------+\n"+
               "| red  | snapper |\n"+
               "+----------------+\n\n"+
               "is:\n\n"+
               "+-------------+\n"+
               "| this | more |\n"+
               "+-------------+\n\n"
    assert_equal(expected, actual)
  end
  
end