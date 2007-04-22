require "test/unit"
require "ruport"

begin
  require "rubygems"
rescue LoadError
  nil
end

class TestFormatPDF < Test::Unit::TestCase

  def test_render_pdf_basic
    begin
      quiet { require "pdf/writer" } 
    rescue LoadError 
      warn "skipping pdf test"; return
    end
    data = [[1,2],[3,4]].to_table
    assert_raise(RuntimeError) { data.to_pdf }

    data.column_names = %w[a b]
    assert_nothing_raised { data.to_pdf }
  end

end
