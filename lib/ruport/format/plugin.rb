class InvalidGraphDataError < RuntimeError; end
class InvalidGraphOptionError < RuntimeError; end

require 'bigdecimal'
require 'tempfile'

class RenderingError < RuntimeError; end

module Ruport
  class Format::Plugin
    
    class << self

      attr_accessor :data
      attr_accessor :options 
      
      include MetaTools

      def helper(name,options={},&block)
        if options[:engines]
          options[:engines].each { |e| 
            helpers[e].send(:define_method, "#{name}_helper", &block)
          }
        elsif options[:engine]
          helpers[options[:engine]].send(  :define_method, 
                                         "#{name}_helper", &block)
        else
          singleton_class.send( :define_method, "#{name}_helper", &block )
        end
      end

      def helpers
        @helpers ||= Hash.new { |h,k| h[k] = Module.new }
      end

      private :singleton_class, :attribute, :attributes, :action
     
      def plugin_name(name=nil); @name ||= name; end
      
      def renderer(render_type,&block)
        m = "render_#{render_type}".to_sym
        block ||= lambda { data } 
        singleton_class.send(:define_method, m, &block)
      end

      def format_field_names(&block)
        singleton_class.send( :define_method, :build_field_names, &block)
      end

      def register_on(*args)
        args.each { |klass|
          if klass.kind_of? Symbol
            klass = Format::Engine.engine_classes[klass]
          end
        
          klass.accept_format_plugin(self)
        }
      rescue NoMethodError
        p caller
      end
      
      def rendering_options(hash={})
        @rendering_options ||= {}
        @rendering_options.merge!(hash)
        @rendering_options.dup
      end
     
      attr_accessor :rendered_field_names
      attr_accessor :pre, :post
      attr_accessor :header, :footer
      
    end
  end       
end
plugins = %w[text csv pdf svg html latex xml_swf]
plugins.each { |p| require "ruport/format/plugin/#{p}_plugin" }
