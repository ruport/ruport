module Ruport
  class Format::Engine
    class Table < Format::Engine      
          
       renderer do
          super
          active_plugin.rendered_field_names = "" 
          build_field_names if (data.respond_to?(:column_names) &&
                                !data.column_names.empty? &&
                                data.column_names && show_field_names)
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
          if active_plugin.respond_to?(:build_field_names)
            active_plugin.rendered_field_names = 
              active_plugin.build_field_names
          end
        end

      end  
      
        alias_engine Table, :table_engine
        Format.build_interface_for Table, :table
        self.show_field_names = true
    end
  end
end

