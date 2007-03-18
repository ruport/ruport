require "test/unit"
require "ruport"

begin
  require "rubygems"
rescue LoadError
  nil
end

class TestFormatCSV < Test::Unit::TestCase

  def test_render_csv_table
    actual = Ruport::Renderer::Table.render_csv { |r| 
      r.data = [[1,2,3],[4,5,6]].to_table 
    }
    assert_equal("1,2,3\n4,5,6\n",actual)

    actual = Ruport::Renderer::Table.render_csv { |r|
      r.data = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    }
    assert_equal("a,b,c\n1,2,3\n4,5,6\n",actual)
  end

  def test_render_csv_group
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [[1,2,3],[4,5,6]],
                                    :column_names => %w[a b c])
    actual = Ruport::Renderer::Group.render(:csv, :data => group,
               :show_table_headers => false )
    assert_equal("test\n\n1,2,3\n4,5,6\n",actual)
  end

  def test_render_csv_grouping
    table = Table(%w[hi chris carter]) << %w[is this annoying] <<
                                          %w[is it funny]
    grouping = Grouping(table,:by => "hi")

    actual = grouping.to_csv #(:show_group_headers => false)

    assert_equal "is\n\nchris,carter\nthis,annoying\nit,funny\n\n", actual
  end

  def test_render_csv_grouping_without_header
    table = Table(%w[hi chris carter]) << %w[is this annoying] <<
                                          %w[is it funny]
    grouping = Grouping(table,:by => "hi")

    actual = grouping.to_csv :show_table_headers => false

    assert_equal "is\n\nthis,annoying\nit,funny\n\n", actual
  end
 
  def test_render_csv_row
    actual = Ruport::Renderer::Row.render_csv { |r| r.data = [1,2,3] }
    assert_equal("1,2,3\n", actual)
  end

  def test_format_options
    a = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    assert_equal "a\tb\tc\n1\t2\t3\n4\t5\t6\n", 
      a.as(:csv,:format_options => { :col_sep => "\t" })
  end

  def test_layout_header
    actual = Ruport::Renderer::Table.render_csv { |r|
      r.data = [[1,2,3],[4,5,6]].to_table(%w[a b c])
      r.options { |o| o.show_table_headers = false }
    }
    assert_equal("1,2,3\n4,5,6\n",actual)
  end  

  # -----------------------------------------------------------------------
  # BUG TRAPS
  # ------------------------------------------------------------------------
  
  def test_ensure_group_names_are_converted_to_string
    g = Grouping((Table(%w[a b c])<<[1,2,3]<<[1,1,4]), :by => "a")
    assert_equal "1\n\nb,c\n2,3\n1,4\n\n", g.to_csv
  end


end
