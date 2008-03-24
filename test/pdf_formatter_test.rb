#!/usr/bin/env ruby -w
require File.join(File.expand_path(File.dirname(__FILE__)), "helpers")

class TestRenderPDFTable < Test::Unit::TestCase
  
  def setup
    Ruport::Formatter::Template.create(:simple) do |format|
      format.page = {
        :size   => "LETTER",
        :layout => :landscape
      }
      format.text = {
        :font_size => 16
      }
      format.table = {
        :show_headings  => false
      }
      format.column = {
        :alignment  => :center,
        :width      => 50
      }
      format.heading = {
        :alignment  => :right,
        :bold       => false,
        :title      => "Test"
      }
      format.grouping = {
        :style => :separated
      }
    end
  end

  def test_render_pdf_basic  
    # can't render without column names
    data = Table([], :data => [[1,2],[3,4]])
    assert_raise(Ruport::FormatterError) do
      data.to_pdf 
    end      

    data.column_names = %w[a b]
    assert_nothing_raised { data.to_pdf }
    
    assert_nothing_raised { Table(%w[a b c]).to_pdf }
  end     
                              
  # this is mostly to check that the transaction hack gets called
  def test_relatively_large_pdf
     table = Table(File.join(File.expand_path(File.dirname(__FILE__)), 
                   %w[samples dates.csv]))  
     table.reduce(0..99)
     assert_nothing_raised { table.to_pdf }
  end 
     
  # this is just to make sure that the column_opts code is being called.
  # FIXME: add mocks to be sure
  def test_table_with_options
    data = Table(%w[a b], :data => [[1,2],[3,4]])
    assert_nothing_raised do
      data.to_pdf(:table_format => { 
            :column_options => { :justification => :center } } ) 
    end
  end
  
  def test_render_with_template
    formatter = Ruport::Formatter::PDF.new
    formatter.options = Ruport::Controller::Options.new
    formatter.options.template = :simple
    formatter.apply_template
    
    assert_equal "LETTER", formatter.options.paper_size
    assert_equal :landscape, formatter.options.paper_orientation

    assert_equal 16, formatter.options.text_format[:font_size]

    assert_equal false, formatter.options.table_format[:show_headings]

    assert_equal :center,
      formatter.options.table_format[:column_options][:justification]
    assert_equal 50,
      formatter.options.table_format[:column_options][:width]
      
    assert_equal :right,
      formatter.options.table_format[:column_options][:heading][:justification]
    assert_equal false,
      formatter.options.table_format[:column_options][:heading][:bold]
    assert_equal "Test",
      formatter.options.table_format[:column_options][:heading][:title]

    assert_equal :separated, formatter.options.style
  end
  
  def test_options_hashes_override_template
    opts = nil
    table = Table(%w[a b c])
    table.to_pdf(
      :template => :simple,
      :page_format => {
        :size  => "LEGAL",
        :layout => :portrait
      },
      :text_format => {
        :font_size  => 20
      },
      :table_format => {
        :show_headings  => true
      },
      :column_format => {
        :alignment => :left,
        :width => 25
      },
      :heading_format => {
        :alignment => :left,
        :bold => true,
        :title => "Replace"
      },
      :grouping_format => {
        :style  => :inline
      }
    ) do |r|
      opts = r.options
    end
    
    assert_equal "LEGAL", opts.paper_size
    assert_equal :portrait, opts.paper_orientation

    assert_equal 20, opts.text_format[:font_size]

    assert_equal true, opts.table_format[:show_headings]

    assert_equal :left, opts.table_format[:column_options][:justification]
    assert_equal 25, opts.table_format[:column_options][:width]
      
    assert_equal :left,
      opts.table_format[:column_options][:heading][:justification]
    assert_equal true, opts.table_format[:column_options][:heading][:bold]
    assert_equal "Replace", opts.table_format[:column_options][:heading][:title]

    assert_equal :inline, opts.style
  end

  def test_individual_options_override_template
    opts = nil
    table = Table(%w[a b c])
    table.to_pdf(
      :template => :simple,
      :paper_size => "LEGAL",
      :paper_orientation => :portrait,
      :text_format => { :font_size  => 20 },
      :table_format => {
        :show_headings  => true,
        :column_options => {
          :justification => :left,
          :width => 25,
          :heading => {
            :justification => :left,
            :bold => true,
            :title => "Replace"
          }
        }
      },
      :style => :inline
    ) do |r|
      opts = r.options
    end
    
    assert_equal "LEGAL", opts.paper_size
    assert_equal :portrait, opts.paper_orientation

    assert_equal 20, opts.text_format[:font_size]

    assert_equal true, opts.table_format[:show_headings]

    assert_equal :left, opts.table_format[:column_options][:justification]
    assert_equal 25, opts.table_format[:column_options][:width]
      
    assert_equal :left,
      opts.table_format[:column_options][:heading][:justification]
    assert_equal true, opts.table_format[:column_options][:heading][:bold]
    assert_equal "Replace", opts.table_format[:column_options][:heading][:title]

    assert_equal :inline, opts.style
  end

  #--------BUG TRAPS--------#
  
  # PDF::SimpleTable does not handle symbols as column names
  # Ruport should smartly fix this surprising behaviour (#283) 
  def test_tables_should_render_with_symbol_column_name
    data = Table([:a,:b,:c], :data => [[1,2,3],[4,5,6]])
    assert_nothing_raised { data.to_pdf }
  end   
  
  # draw_table has destructive behavior on nested rendering options (#359)
  def test_draw_table_should_not_destroy_nested_rendering_options
     f = Ruport::Formatter::PDF.new   
     f.options = Ruport::Controller::Options.new 
     f.options[:table_format] =  
       { :column_options => { :heading => {:justification => :center }}}
     f.draw_table Table(%w[a b c], :data => [[1,2,3],[4,5,6]])  
     assert_equal({ :justification => :center }, 
                  f.options[:table_format][:column_options][:heading])      
  end        
    
end    

class TestRenderPDFGrouping < Test::Unit::TestCase                                  
   
  #--------BUG TRAPS----------#
  
  # As of Ruport 0.10.0, PDF's justified group output was throwing
  # UnknownFormatError  (#288)
  def test_group_styles_should_not_throw_error
     table = Table(%w[a b c], :data => [[1,2,3],[4,5,6],[1,7,9]]) 
     grouping = Grouping(table,:by => "a")
     assert_nothing_raised { grouping.to_pdf } 
     assert_nothing_raised { grouping.to_pdf(:style => :inline) }
     assert_nothing_raised { grouping.to_pdf(:style => :offset) }     
     assert_nothing_raised { grouping.to_pdf(:style => :justified) }
     assert_nothing_raised { grouping.to_pdf(:style => :separated) }
     assert_raises(NotImplementedError) do 
       grouping.to_pdf(:style => :red_snapper) 
     end       
  end    
  
  def test_grouping_should_have_consistent_font_size
    a = Table(%w[a b c]) <<  %w[eye like chicken] << %w[eye like liver] << 
                               %w[meow mix meow ] << %w[mix please deliver ] 
    b = Grouping(a, :by => "a")
    splat = b.to_pdf.split("\n") 
    splat.grep(/meow/).each do |m|
      assert_equal '10.0', m.split[5] 
    end                  
    splat.grep(/mix/).each do |m|
      assert_equal '10.0', m.split[5] 
    end                          
    splat.grep(/eye/).each do |m|
      assert_equal '10.0', m.split[5]
    end
  end
  
end

class TestPDFFormatterHelpers < Test::Unit::TestCase   
  
  def test_boundaries
     a = Ruport::Formatter::PDF.new
     
     assert_equal 36, a.left_boundary    
     a.pdf_writer.left_margin = 50 
     assert_equal 50, a.left_boundary   
     
     assert_equal 576, a.right_boundary
     a.pdf_writer.right_margin -= 10  
     assert_equal 586, a.right_boundary 
     
     assert_equal 756, a.top_boundary
     a.pdf_writer.top_margin -= 10
     assert_equal 766, a.top_boundary
     
     assert_equal 36, a.bottom_boundary
     a.pdf_writer.bottom_margin -= 10
     assert_equal 26, a.bottom_boundary             
  end
     
  def test_move_cursor
     a = Ruport::Formatter::PDF.new
     a.move_cursor_to(500)
     assert_equal(500,a.cursor)  
     a.move_cursor(-25)
     assert_equal(475,a.cursor)
     a.move_cursor(50)
     assert_equal(525,a.cursor)
  end           

  def test_move_up
    a = Ruport::Formatter::PDF.new
    a.move_cursor_to(500)
    a.move_up(50)
    assert_equal(550,a.cursor)
    a.move_down(100)
    assert_equal(450,a.cursor)
  end
  
  def test_padding
    a = Ruport::Formatter::PDF.new
    a.move_cursor_to(100)             
    
    # padding on top and bottom
    a.pad(10) do        
      assert_equal 90, a.cursor
      a.move_cursor(-10)      
      assert_equal 80, a.cursor
    end
    assert_equal(70,a.cursor)  
    
    a.move_cursor_to(100)
    
    # padding just on top  
    a.pad_top(10) do
      assert_equal 90, a.cursor
      a.move_cursor(-10)
      assert_equal 80, a.cursor
    end
    
    assert_equal 80, a.cursor   
    
    a.move_cursor_to(100)  
    
    # padding just on bottom
    a.pad_bottom(10) do
      assert_equal 100, a.cursor
      a.move_cursor(-10)
      assert_equal 90, a.cursor
    end  
    
    assert_equal 80, a.cursor        
  end
  
  def test_draw_text_retains_cursor
    a = Ruport::Formatter::PDF.new
    a.move_cursor_to(100)
    
    a.draw_text "foo", :left => a.left_boundary
    assert_equal 100, a.cursor
    
    a.draw_text "foo", :left => a.left_boundary + 50, :y => 500
    assert_equal 100, a.cursor
  end
end  
  
class SimpleController < Ruport::Controller
  stage :foo
  
  class PDF < Ruport::Formatter::PDF
    renders :pdf, :for => SimpleController
    
    build :foo do
      add_text "Blah"
    end
  end
end                                

class TestPDFFinalize < Test::Unit::TestCase

  context "When rendering a PDF" do    
    def specify_finalize_should_be_called
      SimpleController.render_pdf do |r|
        r.formatter.expects(:render_pdf)
      end 
    end
  end
  
end
    