require "ruport"
begin; require 'rubygems'; rescue LoadError; nil; end
require "test/unit"

class TestLatex < Test::Unit::TestCase

  def setup
    @data = [[1,2,3,2],[3,4,5,6]].to_table(%w[a b c d])
  end

  # basic test to ensure bar charts render
  def test_table_to_latex
    report = Ruport::Format.table_object :plugin => :latex, :data => @data
    output = report.render
    assert_equal "\\documentclass", output[/\\documentclass/]
    assert_equal "\\begin{document}", output[/\\begin\{document\}/]
    assert_equal "\\end{document}", output[/\\end\{document\}/]
  end

end
