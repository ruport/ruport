# renderer.rb : General purpose formatted data renderer for Ruby Reports
#
# Copyright December 2006, Gregory Brown.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.


# This class implements the core engine for Ruport's formatting system.  It is
# designed to implement the low level tools necessary to build report renderers
# for different kinds of tasks.  See Renderer::Table for a tabular data renderer
# and Renderer::Graph for graphing support.  
#
# This class can easily be extended to build custom formatting engines, but if
# you do not need that, may not be relevant to study for your use of Ruport.
class Ruport::Renderer
  module Helpers
    def prepare(name)
      maybe "prepare_#{name}"
    end

    def build(names,prefix=nil)
      return maybe("build_#{names}") if prefix.nil?
      names.each { |n| maybe "build_#{prefix}_#{n}" }
    end

    def finalize(name)
      maybe "finalize_#{name}"
    end

    private 

    def maybe(something)
      plugin.send something if plugin.respond_to? something
    end
  end
  # allows you to register a format with the renderer.
  #
  # example:
  #
  #   class MyPlugin < Ruport::Format::Plugin
  #
  #     # plugin code ...
  #
  #     SomeRenderer.add_format self, :my_plugin
  #
  #   end
  def self.add_format(format,name=nil)
    return formats[name] = format if name

    add_core_format(format)   
 end


  # reader for formats.  Defaults to a hash
  def self.formats
    @formats ||= {}
  end

  # same as Renderer#layout, but can be used to specify a default layout object
  # for the entire class.  
  def self.layout
    @layout ||= Ruport::Layout::Component.new
    yield(@layout) if block_given?

    return @layout
  end

  # creates a new instance of the renderer
  # then looks up the formatting plugin and creates a new instance of that as
  # well.  If a block is given, the renderer instance is yielded.
  #
  # The run() method is then called on the renderer method.
  #
  # Finally, the value of the plugin's output accessor is returned
  def self.render(format,&block)
    rend = build format, &block
    rend.run
    return rend.plugin.output
  end


  # creates a new instance of the renderer and sets it to use the specified
  # formatting plugin (by name).  If a block is given, the renderer instance is
  # yielded.  
  #
  # Returns the renderer instance.
  def self.build(format)
    rend = self.new

    rend.send(:use_plugin,format)
    rend.send(:layout=, layout.dup)
    yield(rend) if block_given?
    return rend
  end

  attr_accessor :format
  attr_reader   :data

  # Generates a layout object and passes it along to the current formatting
  # plugin.  If the block form is used, the layout object will be yielded for
  # modification.
  #
  def layout
    @layout ||= Ruport::Layout::Component.new
    yield(@layout) if block_given?

    plugin.layout = @layout
  end

  # sets +data+ attribute on both the renderer and any active plugin
  def data=(val)
    @data = val.dup
    plugin.data = @data if plugin
  end

  # General purpose openstruct which is shared with the current formatting
  # plugin.
  def options
    yield(plugin.options) if block_given?
    plugin.options
  end

  # when no block is given, returns active plugin
  #
  # when a block is given with a block variable, sets the block variable to the
  # plugin.  
  #
  # when a block is given without block variables, instance_evals the block
  # within the context of the plugin
  def plugin(&block)
    if block.nil?
      return @plugin 
    elsif block.arity > 0
      yield(@plugin)
    else
      @plugin.instance_eval(&block)
    end
    return @plugin
  end

  private
  
  attr_writer :plugin

  #internal layout accessor.
  def layout=(lay)
    @layout = lay
    plugin.layout = lay
  end

  # tries to autoload and register a format which is part of the Ruport::Format
  # module.  For internal use only.
  def self.add_core_format(format)
    try_require(format)
    
    klass = Ruport::Format.const_get(
      Ruport::Format.constants.find { |c| c =~ /#{format}/i })
    
    formats[format] = klass
  end

  # internal shortcut for format registering
  def self.add_formats(*formats)
    formats.each { |f| add_format f }
  end

  # Trys to autoload a given format,
  # silently fails
  def self.try_require(format)
    begin
      require "ruport/format/#{format}"  
    rescue LoadError
      nil
    end
  end

  # selects a plugin for use by format name
  def use_plugin(format)
    self.plugin = self.class.formats[format].new
  end

  # provides a shortcut to render() to allow
  # render(:csv) to become render_csv
  def self.method_missing(id,*args,&block)
    id.to_s =~ /^render_(.*)/
    $1 ? render($1.to_sym,&block) : super
  end


end

require "ruport/renderer/table"
require "ruport/renderer/graph"
