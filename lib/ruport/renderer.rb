# renderer.rb : General purpose formatted data renderer for Ruby Reports
#
# Copyright December 2006, Gregory Brown.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.


# This class implements the core renderer for Ruport's formatting system.  It is
# designed to implement the low level tools necessary to build report renderers
# for different kinds of tasks.  See Renderer::Table for a tabular data
# renderer.  
#
# This class can easily be extended to build custom formatting systems, but if
# you do not need that, it may not be relevant to study for your use of Ruport.
class Ruport::Renderer

  class RequiredOptionNotSet < RuntimeError; end
  class UnknownFormatError < RuntimeError; end
  class StageAlreadyDefinedError < RuntimeError; end
  class RendererNotSetError < RuntimeError; end

  require "ostruct"
  class Options < OpenStruct #:nodoc:
    def to_hash
      @table
    end   
    def [](key)
      send(key)
    end
    def []=(key,value)
      send("#{key}=",value)
    end
  end

  module Hooks #:nodoc:
    module ClassMethods
      def renders_with(renderer,opts={})
        @renderer = renderer.name
        @rendering_options=opts
      end  

      def rendering_options
        @rendering_options
      end
      
      def renders_as_table(options={})
        renders_with Ruport::Renderer::Table,options
      end
       
      def renders_as_row(options={})
        renders_with Ruport::Renderer::Row, options
      end
        
      def renders_as_group(options={})
        renders_with Ruport::Renderer::Group,options
      end 
      
      def renders_as_grouping(options={})
        renders_with Ruport::Renderer::Grouping,options
      end

      def renderer
        return unless @renderer
        @renderer.split("::").inject(Class) { |c,el| c.const_get(el) }
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end      

    def as(format,options={})
      raise RendererNotSetError unless self.class.renderer
      unless self.class.renderer.formats.include?(format)
        raise UnknownFormatError
      end
      self.class.renderer.render(format,
       self.class.rendering_options.merge(options)) do |rend|
        rend.data = send(:renderable_data) rescue self
        yield(rend) if block_given?  
      end
    end  
  end

                          
  module AutoRunner  #:nodoc:
    # called automagically when the report is rendered. Uses the
    # data collected from the earlier methods.
    def _run_

      # ensure all the required options have been set
      unless self.class.required_options.nil?
        self.class.required_options.each do |opt|
          if options.__send__(opt).nil?
            raise RequiredOptionNotSet, "Required option #{opt} not set"
          end
        end
      end

      prepare self.class.first_stage if self.class.first_stage
                
      if formatter.respond_to?(:layout)
        formatter.layout do execute_stages end
      else
        execute_stages
      end

      finalize self.class.final_stage if self.class.final_stage

    end  
    
    def execute_stages
      # call each stage to build the report
      unless self.class.stages.nil?
        self.class.stages.each do |stage|
          self.send(:build,stage)
        end
      end
    end
  end
  
  class << self
    
    attr_accessor :first_stage,:final_stage,:required_options,:stages #:nodoc: 

    def finalize(stage)
      if final_stage
        raise StageAlreadyDefinedError, 'final stage already defined'      
      end
      self.final_stage = stage
    end

    def prepare(stage)
      if first_stage
        raise StageAlreadyDefinedError, "prepare stage already defined"      
      end 
      self.first_stage = stage
    end

    def option(*opts)
      opts.each do |opt|
        opt = "#{opt}="
        define_method(opt) {|t| options.send(opt, t) } 
      end
    end

    def required_option(*opts) 
      self.required_options ||= []
      opts.each do |opt|
        self.required_options << opt 
        option opt
      end
    end

    def stage(*stage_list)
      self.stages ||= []
      stage_list.each { |stage|
        self.stages << stage.to_s 
      }
    end

    def formats
      @formats ||= {}
    end

    def render(*args)
      rend = build(*args) { |r|
        r.setup if r.respond_to? :setup
        yield(r) if block_given?
      }
      if rend.respond_to? :run
        rend.run
      else
        include AutoRunner
      end
      rend._run_ if rend.respond_to? :_run_
      return rend.formatter.output
    end

    # Allows you to set class_wide default options
    # 
    # Example:
    #  
    #  options { |o| o.style = :justified }
    #
    def options
      @options ||= Ruport::Renderer::Options.new
      yield(@options) if block_given?

      return @options
    end

    # Creates a new instance of the renderer and sets it to use the specified
    # formatter (by name).  If a block is given, the renderer instance is
    # yielded.  
    #
    # Returns the renderer instance.
    #
    def build(*args)
      rend = self.new

      rend.send(:use_formatter,args[0])
      rend.send(:options=, options.dup)

      if args[1].kind_of?(Hash)
        d = args[1].delete(:data)
        rend.data = d if d
        args[1].each {|k,v| rend.options.send("#{k}=",v) }
      end

      yield(rend) if block_given?
      return rend
    end
    
    private
    
    # Allows you to register a format with the renderer.
    #
    # example:
    #
    #   class MyFormatter < Ruport::Formatter
    #     # formatter code ...
    #     SomeRenderer.add_format self, :my_formatter
    #   end
    #
    def add_format(format,name=nil)
      formats[name] = format
    end
    
  end

  attr_accessor :format
  attr_writer :formatter  

  def data
    formatter.data
  end

  # Sets +data+ attribute on the active formatter.
  def data=(val)
    formatter.data = val.dup 
  end

  # Renderer::Options object which is shared with the current formatter.
  def options
    yield(formatter.options) if block_given?
    formatter.options
  end
  
  # If an IO object is given, Formatter#output will use it instead of 
  # the default String.  For Ruport's core renderers, we technically
  # can use any object that supports the << method, but it's meant
  # for IO objects such as File or STDOUT
  #
  def io=(obj)
    options.io=obj    
  end

  # When no block is given, returns active formatter.
  #
  # When a block is given with a block variable, sets the block variable to the
  # formatter.  
  #
  # When a block is given without block variables, instance_evals the block
  # within the context of the formatter.
  #
  def formatter(&block)
    if block.nil?
      return @formatter
    elsif block.arity > 0
      yield(@formatter)
    else
      @formatter.instance_eval(&block)
    end
    return @formatter
  end

  # Provides a shortcut to render() to allow
  # render(:csv) to become render_csv
  #
  def self.method_missing(id,*args,&block)
    id.to_s =~ /^render_(.*)/
    unless args[0].kind_of? Hash
      args = [ (args[1] || {}).merge(:data => args[0]) ]
    end
    $1 ? render($1.to_sym,*args,&block) : super
  end
  
  private  

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
  
  def maybe(something)
    formatter.send something if formatter.respond_to? something
  end    

  def options=(o)
    formatter.options = o
  end
  
  # selects a formatter for use by format name
  def use_formatter(format)
    self.formatter = self.class.formats[format].new
    self.formatter.format = format
  end

end

require "ruport/renderer/table"
require "ruport/renderer/grouping"         
