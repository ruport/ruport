#!/usr/bin/env ruby -w

require_relative 'helpers'

class TestRenderPDFTable < Minitest::Test

  def setup
    Ruport::Formatter::Template.create(:simple) do |format|
      format.page = {
        size:    "LETTER",
        layout:  :landscape
      }
      format.text = {
        font_size:  16
      }
      format.table = {
        show_headings:   false
      }
      format.column = {
        alignment:   :center,
        width:       50
      }
      format.heading = {
        alignment:   :right,
        bold:        false,
        title:       "Test"
      }
      format.grouping = {
        style:  :separated
      }
    end
  end

  def test_render_pdf_errors
    # can't render without column names
    data = Ruport.Table([], data:  [[1,2],[3,4]])
    assert_raises(Ruport::FormatterError) do
      data.to_prawn_pdf
    end

    data.column_names = %w[a b]

    data.to_prawn_pdf
  end

  def test_render_pdf_basic
    expected_output = IO.binread(File.join(__dir__, 'expected_outputs/prawn_pdf_formatter/pdf_basic.pdf.test')).bytes

    data = Ruport.Table(%w[a b c], data: [[1,2,3]])
    # debugging:
    # data.to_prawn_pdf(:file => File.join(__dir__, 'expected_outputs/prawn_pdf_formatter/pdf_actual.pdf.test'))
    actual_output = data.to_prawn_pdf.bytes

    assert_equal expected_output, actual_output
  end

  # this is mostly to check that the transaction hack gets called
  def test_relatively_large_pdf
     table = Ruport.Table(File.join(File.expand_path(File.dirname(__FILE__)), "../test/",
                   %w[samples dates.csv]))
     table.reduce(0..99)
     table.to_prawn_pdf
  end

  #--------BUG TRAPS--------#

  # PDF::SimpleTable does not handle symbols as column names
  # Ruport should smartly fix this surprising behaviour (#283)
  def test_tables_should_render_with_symbol_column_name
    data = Ruport.Table([:a,:b,:c], data:  [[1,2,3],[4,5,6]])
    data.to_prawn_pdf
  end

end

class TestRenderPDFGrouping < Minitest::Test

  #--------BUG TRAPS----------#

  def test_grouping_should_have_consistent_font_size
    a = Ruport.Table(%w[a b c]) <<  %w[eye like chicken] << %w[eye like liver] <<
                               %w[meow mix meow ] << %w[mix please deliver ]
    b = Grouping(a, by:  "a")
    splat = b.to_prawn_pdf.split("\n")
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

class TestPDFFormatterHelpers < Minitest::Test

  def test_move_up
    a = Ruport::Formatter::PrawnPDF.new
    a.move_cursor_to(500)
    a.move_up(50)
    assert_equal(550,a.cursor)
    a.move_down(100)
    assert_equal(450,a.cursor)
  end
end
