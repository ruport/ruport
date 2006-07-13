module Ruport
  class Format::Engine
    require "forwardable"
    
    class << self

      include Enumerable
      extend Forwardable

      def_delegator :@data, :each
      
      def renderer(&block)
        block = lambda { data } unless block_given?
        (class << self; self; end).send(:define_method, :render, &block)
      end

      attr_accessor :engine_klasses
      attr_reader :plugin 
      attr_reader :data
      attr_accessor :klass_binding
      attr_reader :options
      
      def alias_engine(klass,name)
        Format::Engine.engine_klasses ||= {}
        Format::Engine.engine_klasses[name] = klass
      end

      def data=(data)
        @data = data
        active_plugin.data = data.dup if active_plugin
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
        @plugin = p
        @format_plugins[:current] = @format_plugins[p].dup
        @format_plugins[:current].data = self.data.dup if self.data 
      end
      
      def apply_erb
       active_plugin.data = 
         ERB.new(active_plugin.data).result(klass_binding || binding)
      end
 
      def render
        raise "No plugin specified" unless plugin
        raise "No data provided" unless data
        active_plugin.data = data.dup
      end

      def flush_data
        self.data = nil
      end
      
      def accept_format_plugin(klass) 
        format_plugins[klass.format_name] = klass
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
      
      def method_missing(id)
        super unless active_plugin.respond_to?("#{id}_helper")
        return active_plugin.send("#{id}_helper",self)
      end

    end
  end
  
  class Format::Engine::Table < Format::Engine      
        
     renderer do
        super
        active_plugin.rendered_field_names = "" 
        build_field_names if (data.respond_to?(:fields) && 
                              data.fields && show_field_names)
        a = active_plugin.render_table
      end

    class << self

      def rewrite_column(key,&block)
        data.each { |r| r[key] = block[r] }
      end
 
      def num_cols
        data[0].to_a.length
      end

      def prune(limit=data[0].length)
        (0...limit).each do |field|
          last = ""
          data.each_with_index { |e,i|
            next if i.zero? || field.nonzero? && data[i][field-1] 
            last = data[i-1][field] if data[i-1][field]
            data[i][field] = nil if e[field] == last
          }
        end
      end
      
      attr_accessor :show_field_names
      
      private
      
      def build_field_names
        if active_plugin.respond_to?(:build_field_names)
          active_plugin.rendered_field_names = active_plugin.build_field_names
        end
      end

    end  
    
      alias_engine Table, :table_engine
      Format.build_interface_for Table, :table
      self.show_field_names = true
  end

  class Format::Engine::Document < Format::Engine
    
    renderer do
      super
      apply_erb if erb_enabled
      apply_red_cloth if red_cloth_enabled
      active_plugin.render_document
    end

    class << self
      
      attr_accessor :red_cloth_enabled
      attr_accessor :erb_enabled
      
      def apply_red_cloth
        require "redcloth"
        active_plugin.data = RedCloth.new(active_plugin.data).to_html
      end
          
    end
    
    alias_engine Document, :document_engine
    Format.build_interface_for Document, :document 
  end


end
