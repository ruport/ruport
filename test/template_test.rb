#!/usr/bin/env ruby -w
require File.join(File.expand_path(File.dirname(__FILE__)), "helpers") 

class TemplateTest < Test::Unit::TestCase
  
  def setup
    @template_class = Ruport::Formatter::Template.dup
  end
  
  def teardown
    Ruport::Formatter::Template.instance_variable_set(:@templates, nil)
  end
   
  def test_template_should_exist
    @template_class.create(:foo)
    assert_instance_of @template_class, 
                       @template_class[:foo]
  end  
  
  def test_template_creation_yields_an_options_object
    @template_class.create(:foo) do |template|
      template.page_format = { :layout     => :landscape,
                               :paper_size => :letter    }
    end
    assert_equal :landscape, @template_class[:foo].page_format[:layout]
    assert_equal :letter, @template_class[:foo].page_format[:paper_size]     
  end
  
  def test_create_derived_template
    Ruport::Formatter::Template.create(:foo) do |template|
      template.page_format = { :layout     => :landscape,
                               :paper_size => :letter    }
    end
    Ruport::Formatter::Template.create(:bar, :base => :foo)
    assert_equal :landscape,
      Ruport::Formatter::Template[:bar].page_format[:layout]
    assert_equal :letter,
      Ruport::Formatter::Template[:bar].page_format[:paper_size]     
  end
  
  def test_default_template
    assert_nil Ruport::Formatter::Template.default
    Ruport::Formatter::Template.create(:default)
    assert_equal Ruport::Formatter::Template[:default],
      Ruport::Formatter::Template.default
  end
  
end
