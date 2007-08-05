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
class Ruport::Renderer
  
  class RequiredOptionNotSet < RuntimeError #:nodoc:
  end
  class UnknownFormatError < RuntimeError #:nodoc:
  end
  class StageAlreadyDefinedError < RuntimeError #:nodoc: 
  end
  class RendererNotSetError < RuntimeError #:nodoc:
  end
                                          
  require "ostruct"              
  
  # Structure for holding renderer options.  
  # Simplified version of HashWithIndifferentAccess
  class Options < OpenStruct  
    # returns a Hash object.  Use this if you need methods other than []
    def to_hash
      @table
    end            
    # indifferent lookup of an attribute, e.g.
    #
    #  options[:foo] == options["foo"]
    def [](key)
      send(key)
    end 
    
    # Sets an attribute, with indifferent access.
    #  
    #  options[:foo] = "bar"  
    #
    #  options[:foo] == options["foo"] #=> true
    #  options["foo"] == options.foo #=> true
    #  options.foo #=> "bar"
    def []=(key,value)
      send("#{key}=",value)
    end
  end
   
  # This module provides hooks into Ruport's formatting system.
  # It is used to implement the as() method for all of Ruport's data
  # structures, as well as the renders_with and renders_as_* helpers.
  #
  # You can actually use this with any data structure, it will look for a
  # renderable_data(format) method to pass to the <tt>renderer</tt> you 
  # specify, but if that is not defined, it will pass <tt>self</tt>.
  #
  # Examples:
  #
  #   # Render Arrays with Ruport's Row Renderer
  #   class Array
  #     include Ruport::Renderer::Hooks
  #     renders_as_row
  #   end
  #
  #   # >> [1,2,3].as(:csv) 
  #   # => "1,2,3\n" 
  #
  #   # Render Hashes with Ruport's Row Renderer
  #   class Hash
  #      include Ruport::Renderer::Hooks
  #      renders_as_row
  #      attr_accessor :column_order
  #      def renderable_data(format)
  #        column_order.map { |c| self[c] }
  #      end
  #   end
  #
  #   # >> a = { :a => 1, :b => 2, :c => 3 }
  #   # >> a.column_order = [:b,:a,:c]
  #   # >> a.as(:csv)
  #   # => "2,1,3\n"
  module Hooks 
    module ClassMethods 
      
      # Tells the class which renderer as() will forward to.
      #
      # Usage:
      #
      #   class MyStructure
      #     include Renderer::Hooks
      #     renders_with CustomRenderer
      #   end
      #   
      # You can also specify default rendering options, which will be used
      # if they are not overriden by the options passed to as().
      #
      #   class MyStructure
      #     include Renderer::Hooks
      #     renders_with CustomRenderer, :font_size => 14
      #   end
      def renders_with(renderer,opts={})
        @renderer = renderer.name
        @rendering_options=opts
      end  
      
      # The default rendering options for a class, stored as a hash.
      def rendering_options
        @rendering_options
      end
       
      # Shortcut for renders_with(Ruport::Renderer::Table), you
      # may wish to override this if you build a custom table renderer.
      def renders_as_table(options={})
        renders_with Ruport::Renderer::Table,options
      end
      
      # Shortcut for renders_with(Ruport::Renderer::Row), you
      # may wish to override this if you build a custom row renderer. 
      def renders_as_row(options={})
        renders_with Ruport::Renderer::Row, options
      end
      
      # Shortcut for renders_with(Ruport::Renderer::Group), you
      # may wish to override this if you build a custom group renderer.  
      def renders_as_group(options={})
        renders_with Ruport::Renderer::Group,options
      end 
      
      # Shortcut for renders_with(Ruport::Renderer::Grouping), you
      # may wish to override this if you build a custom grouping renderer.
      def renders_as_grouping(options={})
        renders_with Ruport::Renderer::Grouping,options
      end
      
      # The class of the renderer object for the base class.
      #
      # Example:
      # 
      #   >> Ruport::Data::Table.renderer
      #   => Ruport::Renderer::Table
      def renderer
        return unless @renderer
        @renderer.split("::").inject(Class) { |c,el| c.const_get(el) }
      end
    end

    def self.included(base) #:nodoc:
      base.extend(ClassMethods)
    end      
    
    # Uses the Renderer specified by renders_with to generate formatted
    # output.  Passes the return value of the <tt>renderable_data(format)</tt>
    # method if the method is defined, otherwise passes <tt>self</tt> as :data
    #
    # The remaining options are converted to a Renderer::Options object and
    # are accessible in both the renderer and formatter.
    #
    #  Example:
    #
    #    table.as(:csv, :show_table_headers => false)
    def as(format,options={})
      raise RendererNotSetError unless self.class.renderer
      unless self.class.renderer.formats.include?(format)
        raise UnknownFormatError
      end
      self.class.renderer.render(format,
        self.class.rendering_options.merge(options)) do |rend|
          rend.data =
            respond_to?(:renderable_data) ? renderable_data(format) : self
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
    
    # Registers a hook to look for in the Formatter object when the render()
    # method is called.                           
    #
    # Usage:
    #
    #   class MyRenderer < Ruport::Renderer
    #      # other details omitted...
    #      finalize :apple
    #   end
    #
    #   class MyFormatter < Ruport::Formatter
    #      renders :example, :for => MyRenderer
    # 
    #      # other details omitted... 
    #    
    #      def finalize_apple
    #         # this method will be called when MyRenderer tries to render
    #         # the :example format
    #      end
    #   end  
    #
    #  If a formatter does not implement this hook, it is simply ignored.
    def finalize(stage)
      if final_stage
        raise StageAlreadyDefinedError, 'final stage already defined'      
      end
      self.final_stage = stage
    end
    
    # Registers a hook to look for in the Formatter object when the render()
    # method is called.                           
    #
    # Usage:
    #
    #   class MyRenderer < Ruport::Renderer
    #      # other details omitted...
    #      prepare :apple
    #   end
    #
    #   class MyFormatter < Ruport::Formatter
    #      renders :example, :for => MyRenderer
    #
    #      def prepare_apple
    #         # this method will be called when MyRenderer tries to render
    #         # the :example format
    #      end        
    #      
    #      # other details omitted...
    #   end  
    #
    #  If a formatter does not implement this hook, it is simply ignored.
    def prepare(stage)
      if first_stage
        raise StageAlreadyDefinedError, "prepare stage already defined"      
      end 
      self.first_stage = stage
    end
    
    # Registers hooks to look for in the Formatter object when the render()
    # method is called.                           
    #
    # Usage:
    #
    #   class MyRenderer < Ruport::Renderer
    #      # other details omitted...
    #      stage :apple,:banana
    #   end
    #
    #   class MyFormatter < Ruport::Formatter
    #      renders :example, :for => MyRenderer
    #
    #      def build_apple
    #         # this method will be called when MyRenderer tries to render
    #         # the :example format
    #      end 
    #   
    #      def build_banana
    #         # this method will be called when MyRenderer tries to render
    #         # the :example format
    #      end    
    #      
    #      # other details omitted...
    #   end  
    #
    #  If a formatter does not implement these hooks, they are simply ignored.          
    def stage(*stage_list)
      self.stages ||= []
      stage_list.each { |stage|
        self.stages << stage.to_s 
      }
    end
     
    # Defines attribute writers for the Renderer::Options object shared
    # between Renderer and Formatter.
    #
    # usage:
    #   
    #   class MyRenderer < Ruport::Renderer
    #      option :font_size, :font_style
    #      # other details omitted
    #   end
    def option(*opts)       
      opts.each do |opt|                                  
        o = opt 
        unless instance_methods(false).include?(o.to_s)   
          define_method(o) {
             options.send(o.to_s) 
          }     
        end
        opt = "#{opt}="
        define_method(opt) {|t| options.send(opt, t) }
      end
    end
    
    # Defines attribute writers for the Renderer::Options object shared
    # between Renderer and Formatter. Will throw an error if the user does
    # not provide values for these options upon rendering.
    #
    # usage:
    #   
    #   class MyRenderer < Ruport::Renderer
    #      required_option :employee_name, :address
    #      # other details omitted
    #   end
    def required_option(*opts) 
      self.required_options ||= []
      opts.each do |opt|
        self.required_options << opt 
        option opt
      end
    end
    

    # Lists the formatters that are currently registered on a renderer,
    # as a hash keyed by format name.
    #
    # Example:
    # 
    #   >> Ruport::Renderer::Table.formats
    #   => {:html=>Ruport::Formatter::HTML, 
    #   ?>  :csv=>Ruport::Formatter::CSV, 
    #   ?>  :text=>Ruport::Formatter::Text, 
    #   ?>  :pdf=>Ruport::Formatter::PDF}
    def formats
      @formats ||= {}
    end
    
    # Builds up a renderer object, looks up the appropriate formatter,
    # sets the data and options, and then does the following process:
    #
    #   * If the renderer contains a module Helpers, mix it in to the instance.
    #   * If a block is given, yield the Renderer instance  
    #   * If a setup() method is defined on the Renderer, call it
    #   * If the renderer has defined a run() method, call it, otherwise,
    #     include Renderer::AutoRunner. (you usually won't need a run() method )
    #   * call _run_ if it exists (This is provided by default, by AutoRunner)
    #   * If the :file option is set to a file name, appends output to the file
    #   * return the results of formatter.output
    #
    # Note that the only time you will need a run() method is if you can't
    # do what you need to via a helpers module or via setup()
    #
    # Please see the examples/ directory for custom renderer examples, because
    # this is not nearly as complicated as it sounds in most cases.
    def render(*args)
      rend = build(*args) { |r|        
          yield(r) if block_given?   
        r.setup if r.respond_to? :setup
      }
      if rend.respond_to? :run
        rend.run
      else
        include AutoRunner
      end
      rend._run_ if rend.respond_to? :_run_
      if rend.options.file
        File.open(rend.options.file,"w") { |f| f << rend.formatter.output }
      else
        return rend.formatter.output
      end
    end

    # Allows you to set class-wide default options.
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
      if rend.class.const_defined? :Helpers
        rend.formatter.extend(rend.class.const_get(:Helpers))
      end
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
    # Example:
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
  
  # The name of format being used.
  attr_accessor :format  
  
  # The formatter object being used.
  attr_writer :formatter  
  
  # The +data+ that has been passed to the active formatter.
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
