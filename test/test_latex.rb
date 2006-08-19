require "ruport"
require 'rubygems' rescue LoadError nil
require "test/unit"

class TestLatex < Test::Unit::TestCase

  def setup
    @data = [[1,2,3,2],[3,4,5,6]].to_table(%w[a b c d])
  end

  # basic test to ensure bar charts render
  def test_table_to_latex
    report = Ruport::Format.table_object :plugin => :latex, :data => @data
    output = report.render
    assert_not_equal nil, output
  end

  def test_table_to_pdf
    unless `pdflatex` 
      report = Ruport::Format.table_object :plugin => :latex, :data => @data
      report.options = {:format => :pdf}
      output = report.render

      assert_not_equal nil, output
    end
  end
end
