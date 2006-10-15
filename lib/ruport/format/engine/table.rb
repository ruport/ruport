module Ruport
  class Format::Engine
    class Table < Format::Engine      

      include MetaTools
 
       renderer do
        super
        renderer_object.render
       end
       
       action(:renderer_object) {
        @renderer_object ||= Format::Renderer.for(self) do |renderer|
          renderer.actions = [ :init_plugin_field_names, 
                               :build_field_names,
                               :call_plugin_render_table ]
        end
       }

      class << self


        def rewrite_column(key,&block)
          data.each { |r| r[key] = block[r] }
        end

        def num_cols
          data[0].to_a.length
        end

        def prune(limit=data[0].length)
          limit.times do |field|
            last = ""
            data.each_cons(2) { |l,e|
              next if field.nonzero? && e[field-1] 
              last = l[field] if l[field]
              e[field] = nil if e[field] == last
            }
          end
        end
        
        attr_accessor :show_field_names
        
        private
        
        def build_field_names
          return unless data.respond_to?(:column_names) &&
                        data.column_names && !data.column_names.empty? && 
                        show_field_names 

          if active_plugin.respond_to?(:build_field_names)
            active_plugin.rendered_field_names = 
              active_plugin.build_field_names
          end
        end

        def init_plugin_field_names
          active_plugin.rendered_field_names = "" 
        end

        def call_plugin_render_table
          active_plugin.render_table
        end

      end  
      
        alias_engine Table, :table_engine
        Format.build_interface_for Table, :table
        self.show_field_names = true
    end
  end
end

