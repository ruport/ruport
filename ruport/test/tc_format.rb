require "test/unit"

class TestFormat < Test::Unit::TestCase
 
  def setup
    @format = Ruport::Format.new(binding)
  end
  
  def test_filter_erb
    @format.content = "<%= 4 + 2 %>"
    assert_equal "6", @format.filter_erb
    @name = "awesome"
    @format.content = " <%= @name %> "
    assert_equal " awesome ", @format.filter_erb
  end

  def test_filter_red_cloth
    if defined? RedCloth
      @format.content = "* foo\n* bar"
      assert_equal "<ul>\n\t<li>foo</li>\n\t\t<li>bar</li>\n\t</ul>",
                   @format.filter_red_cloth
     end
  end

  def filter_ruby
    @format.content = "Hash.new"
    assert_equal({},@format.filter_ruby)
  end

  def test_register_filter
      Ruport::Format.register_filter(:lower) { |content| content.downcase }
      @format.content = "FoO"
      assert_equal("foo", @format.filter_lower)
  end

end

