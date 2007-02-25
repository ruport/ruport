require "test/unit"
require "ruport"

begin
  require "rubygems"
rescue LoadError
  nil
end

class TestFormatLatex < Test::Unit::TestCase

  def test_render_latex_basic
    data = [[1,2,3,2],[3,4,5,6]].to_table(%w[a b c d])
    output = data.to_latex
    assert_equal "\\documentclass", output[/\\documentclass/]
    assert_equal "\\begin{document}", output[/\\begin\{document\}/]
    assert_equal "\\end{document}", output[/\\end\{document\}/]
  end

  def test_render_latex_row
    actual = Ruport::Renderer::Row.render_latex { |r| r.data = [1,2,3] }
    assert_equal("1 & 2 & 3\\\\\n\\hline\n", actual)
  end

end
