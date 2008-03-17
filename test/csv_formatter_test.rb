#!/usr/bin/env ruby -w   
require File.join(File.expand_path(File.dirname(__FILE__)), "helpers")

class TestRenderCSVRow < Test::Unit::TestCase
  def test_render_csv_row
    actual = Ruport::Controller::Row.render_csv(:data => [1,2,3])
    assert_equal("1,2,3\n", actual)
  end
end

class TestRenderCSVTable < Test::Unit::TestCase
  
  def setup
    Ruport::Formatter::Template.create(:simple) do |format|
      format.table = {
        :show_headings  => false
      }
      format.grouping = {
        :style          => :justified,
        :show_headings  => false
      }
      format.format_options = { :col_sep => ":" }
    end
  end

  def test_render_csv_table
    actual = Ruport::Controller::Table.render_csv do |r| 
      r.data = Table([], :data => [[1,2,3],[4,5,6]])
    end
    assert_equal("1,2,3\n4,5,6\n",actual)

    actual = Ruport::Controller::Table.render_csv do |r|
      r.data = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
    end
    assert_equal("a,b,c\n1,2,3\n4,5,6\n",actual)
  end   
  
  def test_format_options
    a = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
    assert_equal "a\tb\tc\n1\t2\t3\n4\t5\t6\n", 
      a.as(:csv,:format_options => { :col_sep => "\t" })
  end

  def test_table_headers
    actual = Ruport::Controller::Table.
             render_csv(:show_table_headers => false, 
                        :data => Table(%w[a b c], :data => [[1,2,3],[4,5,6]]))
    assert_equal("1,2,3\n4,5,6\n",actual)
  end
     
  def test_render_with_template
    formatter = Ruport::Formatter::CSV.new
    formatter.options = Ruport::Controller::Options.new
    formatter.options.template = :simple
    formatter.apply_template
    
    assert_equal false, formatter.options.show_table_headers

    assert_equal :justified, formatter.options.style
    assert_equal false, formatter.options.show_group_headers
    
    assert_equal ":", formatter.options.format_options[:col_sep]
  end

  def test_options_hashes_override_template
    opts = nil
    table = Table(%w[a b c])
    table.to_csv(
      :template => :simple,
      :table_format => {
        :show_headings  => true
      },
      :grouping_format => {
        :style => :raw,
        :show_headings  => true
      }
    ) do |r|
      opts = r.options
    end
    
    assert_equal true, opts.show_table_headers

    assert_equal :raw, opts.style
    assert_equal true, opts.show_group_headers
  end

  def test_individual_options_override_template
    opts = nil
    table = Table(%w[a b c])
    table.to_csv(
      :template => :simple,
      :show_table_headers => true,
      :style => :raw,
      :show_group_headers => true,
      :format_options => { :col_sep => ";" }
    ) do |r|
      opts = r.options
    end
    
    assert_equal true, opts.show_table_headers

    assert_equal :raw, opts.style
    assert_equal true, opts.show_group_headers
    
    assert_equal ";", opts.format_options[:col_sep]
  end
end     

class TestRenderCSVGroup < Test::Unit::TestCase

  def test_render_csv_group
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [[1,2,3],[4,5,6]],
                                    :column_names => %w[a b c])
    actual = Ruport::Controller::Group.
             render_csv(:data => group, :show_table_headers => false )
    assert_equal("test\n\n1,2,3\n4,5,6\n",actual)
  end 
  
end

class RenderCSVGrouping < Test::Unit::TestCase
  def test_render_csv_grouping
    table = Table(%w[hi red snapper]) << %w[is this annoying] <<
                                          %w[is it funny]
    grouping = Grouping(table,:by => "hi")

    actual = grouping.to_csv

    assert_equal "is\n\nred,snapper\nthis,annoying\nit,funny\n\n", actual
  end

  def test_render_csv_grouping_without_header
    table = Table(%w[hi red snapper]) << %w[is this annoying] <<
                                          %w[is it funny]
    grouping = Grouping(table,:by => "hi")

    actual = grouping.to_csv :show_table_headers => false

    assert_equal "is\n\nthis,annoying\nit,funny\n\n", actual
  end  

  def test_alternative_styles
    g = Grouping((Table(%w[a b c]) << [1,2,3] << [1,1,4] <<
                                      [2,1,2] << [1,9,1] ), :by => "a")
    
    assert_raise(NotImplementedError) { g.to_csv :style => :not_real }

    assert_equal "a,b,c\n1,2,3\n,1,4\n,9,1\n\n2,1,2\n\n", 
                 g.to_csv(:style => :justified)

    assert_equal "a,b,c\n1,2,3\n1,1,4\n1,9,1\n\n2,1,2\n\n",
                  g.to_csv(:style => :raw) 
  end

  # -----------------------------------------------------------------------
  # BUG TRAPS
  # ------------------------------------------------------------------------
  
  def test_ensure_group_names_are_converted_to_string
    g = Grouping((Table(%w[a b c])<<[1,2,3]<<[1,1,4]), :by => "a")
    assert_equal "1\n\nb,c\n2,3\n1,4\n\n", g.to_csv
  end
end