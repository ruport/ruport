require 'test/unit'
require 'ruport'

class DummyText < Ruport::Format::Plugin
  def build_header
    output << "header\n"
  end
  def build_body
    output << "body\n"
  end
  def build_footer
    output << "footer\n"
  end
end


class TrivialRenderer < Ruport::Renderer
  add_format DummyText, :text 

  def run
    plugin do
      build_header
      build_body
      build_footer
    end
  end

end

class RendererWithHelpers < Ruport::Renderer
  include Ruport::Renderer::Helpers

  add_format DummyText, :text

  option :subtitle

  stage :header
  stage :body
  stage :footer

  finalize :document
end


class TestRenderer < Test::Unit::TestCase

  def test_trivial
    actual = TrivialRenderer.render(:text)
    assert_equal "header\nbody\nfooter\n", actual
  end

  def test_formats
    assert_equal( {}, Ruport::Renderer.formats )
    assert_equal( { :text => DummyText } , TrivialRenderer.formats )
  end

  def test_try_require
    assert_not_nil Ruport::Renderer.try_require(:csv)
    assert_nil Ruport::Renderer.try_require(:not_a_plugin)
  end

   def test_stage_helper
     assert RendererWithHelpers.stages.include?('body')
   end
 
   def test_finalize_helper
     assert_equal :document, RendererWithHelpers.final_stage
   end
 
   def test_finalize_again
     assert_raise(RuntimeError) { RendererWithHelpers.finalize :report }
   end
 
   def test_renderer_using_helpers
     actual = RendererWithHelpers.render(:text)
     assert_equal "header\nbody\nfooter\n", actual
 
     actual = RendererWithHelpers.render_text
     assert_equal "header\nbody\nfooter\n", actual
   end
 
   def test_option_helper
     RendererWithHelpers.render_text do |r|
       r.subtitle = "Test Report"
       assert_equal "Test Report", r.options.subtitle
     end
   end
 
   def test_required_option_helper
     RendererWithHelpers.required_option :title
 
     RendererWithHelpers.render_text do |r|
       r.title = "Test Report"
       assert_equal "Test Report", r.options.title
     end
   end
 
   def test_without_required_option
     RendererWithHelpers.required_option :title
 
     assert_raise(RuntimeError) { RendererWithHelpers.render(:text) }
   end


  def test_method_missing
    actual = TrivialRenderer.render_text
    assert_equal "header\nbody\nfooter\n", actual
  end

  def test_plugin
    # normal instance mode
    
    rend = TrivialRenderer.new
    rend.send(:use_plugin,:text)

    assert_kind_of Ruport::Format::Plugin, rend.plugin
    assert_kind_of DummyText, rend.plugin

    # render mode
    TrivialRenderer.render_text do |r|
      assert_kind_of Ruport::Format::Plugin, r.plugin
      assert_kind_of DummyText, r.plugin
    end

    assert_equal "body\n", rend.plugin { build_body }.output

    rend.plugin.clear_output
    assert_equal "", rend.plugin.output
  end

end
