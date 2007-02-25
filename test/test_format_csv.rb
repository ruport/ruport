require "test/unit"
require "ruport"

begin
  require "rubygems"
rescue LoadError
  nil
end

class TestFormatCSV < Test::Unit::TestCase

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

  def test_render_csv_row
    actual = Ruport::Renderer::Row.render_csv { |r| r.data = [1,2,3] }
    assert_equal("1,2,3\n", actual)
  end

  def test_layout_header
    actual = Ruport::Renderer::Table.render_csv { |r|
      r.data = [[1,2,3],[4,5,6]].to_table(%w[a b c])
      r.options { |o| o.show_table_headers = false }
    }
    assert_equal("1,2,3\n4,5,6\n",actual)
  end  

end
