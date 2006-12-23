require "test/unit"
require "ruport"

begin
  require "rubygems"
rescue LoadError
  nil
end

class MockGraphPlugin < Ruport::Format::Plugin
  def prepare_graph 
    output << "prepare"
  end
  def build_graph
    output << "build"
  end
  def finalize_graph
    output << "finalize"
  end
end

Ruport::Renderer::Graph.add_format MockGraphPlugin, :mock

class TestGraphRenderer < Test::Unit::TestCase
  
  def test_basics
    out = Ruport::Renderer::Graph.render_mock do |r|
      r.layout do |l|
        assert l.height.kind_of?(Numeric)
        assert l.width.kind_of?(Numeric)
        assert_equal :line, l.style
      end
    end

    assert_equal("preparebuildfinalize",out)    
  end

  def test_report_shortcut
    a = Ruport::Report.new
    a.extend(Ruport::Report::Graph)

    p = lambda { |e| e.data = [[1,2,3]].to_table(%w[a b c]) }

    b = a.build_graph(&p)
    c = b.run
    assert_not_nil b.plugin.output

    assert_equal c, a.render_graph(&p)

  end
  
end


class TestSVGPlugin < Test::Unit::TestCase

  def test_output
    assert_not_nil Ruport::Renderer::Graph.render_svg { |r|
      r.data = [[1,2,3],[4,5,6]].to_table
    }
  end

end

class TestXMLSWFPlugin < Test::Unit::TestCase

  def test_output
  
    expected = <<-EOS
<chart>
  <chart_type>line</chart_type>
  <chart_data>
    <row>
      <null/>
    </row>
    <row>
      <string>Region 0</string>
      <number>1</number>
      <number>2</number>
      <number>3</number>
    </row>
    <row>
      <string>Region 1</string>
      <number>4</number>
      <number>5</number>
      <number>6</number>
    </row>
  </chart_data>
</chart>
EOS
    assert_equal expected,
    Ruport::Renderer::Graph.render_xml { |r|
      r.data = [[1,2,3],[4,5,6]].to_table
    }
  end

end
