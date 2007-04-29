require "test/unit"
require "ruport"

begin
  require "rubygems"
rescue LoadError
  nil
end                        

#require "pdf/writer"    

class TestFormatPDF < Test::Unit::TestCase

  def test_render_pdf_basic
    data = [[1,2],[3,4]].to_table
    assert_raise(Ruport::FormatterError) { 
      data.to_pdf 
    }

    data.column_names = %w[a b]
    assert_nothing_raised { data.to_pdf }
  end 
  
  #--------BUG TRAPS--------#
  
  # PDF::SimpleTable does not handle symbols as column names
  # Ruport should smartly fix this surprising behaviour (#283) 
  def test_tables_should_render_with_symbol_column_name
    data = [[1,2,3],[4,5,6]].to_table([:a,:b,:c])
    assert_nothing_raised { data.to_pdf }
  end
  

end
