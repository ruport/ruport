class InvalidPluginError < RuntimeError; end

module Ruport
  class Format::Engine
    require "forwardable"
    require "enumerator"
    class << self

      include Enumerable
      include MetaTools
      extend Forwardable

      attr_accessor :engine_classes
      attr_reader :plugin 
      attr_reader :data
      attr_accessor :class_binding
      attr_reader :options
      
      def_delegator :@data, :each
      private :attribute, :attributes, :singleton_class, :action

      def renderer(&block)
        block = lambda { data } unless block_given?
        singleton_class.send(:define_method, :render,&block)
      end
      
      def alias_engine(klass,name)
        singleton_class.send(:define_method,:engine_name) { name }
        Format::Engine.engine_classes ||= {}
        Format::Engine.engine_classes[name] = klass
      end

      def data=(stuff)
        return unless stuff
        @data = stuff
        active_plugin.data = stuff.dup if active_plugin
      end

      def options=(opts)
        @options = opts
        active_plugin.options = options if active_plugin
      end
      
      def active_plugin
        return yield(@format_plugins[:current]) if block_given?
        @format_plugins[:current]  
      end

      def plugin=(p)
        if @format_plugins[p].nil?
          raise(InvalidPluginError, 
                'The requested plugin and engine combination is invalid') 
        end

        @plugin = p
        @format_plugins[:current] = @format_plugins[p].dup
        @format_plugins[:current].data = self.data.dup if self.data 
      end
      
      def apply_erb
       active_plugin.data = 
         ERB.new(active_plugin.data).result(class_binding || binding)
      end
 
      def render
        raise "No plugin specified" unless plugin
        active_plugin.data = data.dup if data 
        if active_plugin.respond_to? :init_plugin_helper
           active_plugin.init_plugin_helper(self)
        end
      end

      def flush_data
        self.data = nil
      end
      
      def accept_format_plugin(klass) 
        format_plugins[klass.plugin_name] = klass
      end

      private  

      def format_plugins
        @format_plugins ||= {}
      end

      def plugin_names
        format_plugins.keys
      end

      def plugins
        format_plugins.values
      end 
      
      def method_missing(id,*args)
        active_plugin.extend active_plugin.helpers[engine_name]
        super unless active_plugin.respond_to?("#{id}_helper")
        return active_plugin.send("#{id}_helper",self)
      end

    end
    
    private_class_method :new
  end
end

engines = %w[graph invoice table document]
engines.each { |e| require "ruport/format/engine/#{e}" }
