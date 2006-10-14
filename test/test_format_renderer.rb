require "test/unit"
require "ruport"

class SimpleRenderableObject

  def initialize
    @value = ""
  end

  def a
    @value << "a" << baz
  end

  def b
    @value << "b" << baz
  end

  def dup
    c = self.class.new
    c.instance_variable_set(:@value,@value.dup)
    c.baz = baz.dup if baz; c
  end

  attr_accessor :baz

end

class TestFormatRenderer < Test::Unit::TestCase
  
  def setup
    r_obj = SimpleRenderableObject.new
    @renderer = Ruport::Format::Renderer.for(r_obj) do |renderer|
      renderer.actions  :a, :b
      renderer.property :baz, "d"
    end
  end

  def test_simple_render
    assert_equal ( "a" << "d" << "b" << "d" ), @renderer.render
    @renderer.actions = [:b, :a]
    assert_equal ( "b" << "d" << "a" << "d"), @renderer.render
    @renderer.property :baz, "c"
    assert_equal ( "b" << "c" << "a" << "c" ) , @renderer.render
  end

  def test_changes_are_okay_after_renderer_created
    @renderer.render
    @renderer.instance_eval do
      @renderable_object.instance_variable_set(:@value,"foo")
    end
    assert_equal ("foo" << "a" << "d" << "b" << "d"), @renderer.render
  end

  def test_add_action
    @renderer.define_action(:bang) { |o| o.a + o.b } 
    @renderer.actions << :bang

    obj = @renderer.instance_variable_get(:@renderable_object).dup
    obj.baz = "d"
    obj.a; obj.b
    
    assert_equal( obj.a + obj.b, @renderer.render )
  end

  def test_original_object_untouched
    @renderer.define_action(:bang) { |o| o.b + o.a } 
    @renderer.actions << :bang

    @renderer.render
    obj = @renderer.instance_variable_get(:@renderable_object)
    assert_nil(obj.baz)
    assert_equal("",obj.instance_variable_get(:@value))
  end

  def test_insert_action
    @renderer.define_action(:c) { |o| o.baz = "c" }
    actions = @renderer.actions.dup

    @renderer.insert_action(:c, :at => :beginning )
    assert_equal("acbc",@renderer.render)

    @renderer.actions = actions
    @renderer.insert_action(:c, :at => :end )
    assert_equal("c",@renderer.render)

    @renderer.actions = actions
    @renderer.insert_action(:c, :after => :a)
    assert_equal("adbc",@renderer.render)

    @renderer.actions = actions
    @renderer.insert_action(:c, :before => :b)
    assert_equal("adbc",@renderer.render)

    @renderer.actions = actions
    @renderer.insert_action(:c, :before => :a)
    assert_equal("acbc",@renderer.render)

    @renderer.actions = actions
    @renderer.insert_action(:c, :at => 1)
    assert_equal("adbc",@renderer.render)
  end

  def test_alias_action
    
    #tests object actions
    @renderer.alias_action :foo, :a
    
    @renderer.actions = [:a]
    assert_equal "ad", @renderer.render

    @renderer.actions = [:foo]
    assert_equal "ad", @renderer.render

    @renderer.define_action(:a) { "apple" }

    @renderer.actions = [:a]
    assert_equal "apple", @renderer.render

    @renderer.actions = [:foo]
    assert_equal "ad", @renderer.render

    #tests renderer actions
    @renderer.alias_action :bar, :foo

    @renderer.actions = [:foo]
    assert_equal "ad", @renderer.render

    @renderer.actions = [:bar]
    assert_equal "ad", @renderer.render

    @renderer.define_action(:foo) { "banana" }
    @renderer.actions = [:foo]
    assert_equal "banana", @renderer.render

    @renderer.actions = [:bar]
    assert_equal "ad", @renderer.render

  end

end
