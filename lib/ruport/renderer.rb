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

  require "ruport/renderer/options"

  module Helpers #:nodoc:
    module ClassMethods

      # establish some class instance variables for storing require data
      attr_accessor :first_stage,:final_stage,:required_options,:stages

      # allow the report designer to specify what method will 
      # render the report  e.g.
      #   finalize :document
      #
      def finalize(stage)
        raise 'final stage already defined' if final_stage
        self.final_stage = stage
      end

      # allow the report designer to specify a preparation stage for their
      # report, e.g.
      #
      #   prepare :document
      #
      def prepare(stage)
        raise "prepare stage already defined" if first_stage
        self.first_stage = stage
      end

      # allow the report designer to specify options that can be used to build
      # the report. These are generally used for defining rendering options or
      # data
      # e.g.
      #   option :report_title
      #   option :table_width
      def option(opt)
        opt = "#{opt.to_s}="
        define_method(opt) {|t| options.send(opt, t) }
      end

      # allow the report designer to specify a compulsory option
      # e.g.
      #   required_option :freight
      #   required_option :tax
      def required_option(opt)
        self.required_options ||= []
        self.required_options << opt
        option opt
      end
 
      # allow the report designer to specify the stages that will be used to
      # build the report
      # e.g.
      #   stage :document_header
      #   stage :document_body
      #   stage :document_footer
      def stage(stage)
        self.stages ||= []
        self.stages << stage.to_s
      end
    end
 
    def self.included(base)
      base.extend ClassMethods
    end

    # called automagically when the report is rendered. Uses the
    # data collected from the earlier methods.
    def run

      # ensure all the required options have been set
      unless self.class.required_options.nil?
        self.class.required_options.each do |opt|
          if options.__send__(opt).nil?
            raise "Required option #{opt} not set"
          end
        end
      end

      prepare self.class.first_stage if self.class.first_stage

      # call each stage to build the report
      unless self.class.stages.nil?
        self.class.stages.each do |stage|
          self.build(stage)
        end
      end

      finalize self.class.final_stage if self.class.final_stage

    end

 
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

  # creates a new instance of the renderer
  # then looks up the formatting plugin and creates a new instance of that as
  # well.  If a block is given, the renderer instance is yielded.
  #
  # The run() method is then called on the renderer method.
  #
  # Finally, the value of the plugin's output accessor is returned
  def self.render(*args)
    rend = build(*args) { |r|
      r.setup if r.respond_to? :setup
      yield(r) if block_given?
    }
    rend.run
    return rend.plugin.output
  end

  
  
  def self.options
    @options ||= Ruport::Renderer::Options.new
    yield(@options) if block_given?

    return @options
  end

  # creates a new instance of the renderer and sets it to use the specified
  # formatting plugin (by name).  If a block is given, the renderer instance is
  # yielded.  
  #
  # Returns the renderer instance.
  def self.build(*args)
    rend = self.new

    rend.send(:use_plugin,args[0])
    rend.send(:options=, options.dup)

    if args[1].kind_of?(Hash)
      args[1].each {|k,v| rend.options.send("#{k}=",v) }
    end

    yield(rend) if block_given?
    return rend
  end

  attr_accessor :format
  attr_reader   :data

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
  
  def io=(obj)
    options.io=obj    
  end

  def options=(o)
    plugin.options = o
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
    self.plugin.format = format
  end

  # provides a shortcut to render() to allow
  # render(:csv) to become render_csv
  def self.method_missing(id,*args,&block)
    id.to_s =~ /^render_(.*)/
    $1 ? render($1.to_sym,*args,&block) : super
  end

end

require "ruport/renderer/table"
require "ruport/renderer/graph"
