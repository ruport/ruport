module Ruport
  class Format::Plugin
    class TextPlugin < Format::Plugin
      rendering_options :erb_enabled => true, :red_cloth_enabled => false

      renderer :document
      
      renderer :table do 
        require "ruport/system_extensions" 
        
        return "" if data.length == 0; 
        th = "#{rendered_field_names}#{hr}"
       
        data.each { |r|
          r.each_with_index { |f,i|
            r[i] = f.to_s.center(max_col_width(i))
          }
        }
        
        a = data.inject(th){ |s,r|
          s + "| #{r.to_a.join(' | ')} |\n"
        } << hr

        width = self.right_margin || SystemExtensions.terminal_width
        
        a.to_a.each { |r|
           r.gsub!(/\A.{#{width+1},}/) { |m| m[0,width-2] + ">>" }
        }.join
      end
      
      format_field_names do
        return "" if data.length == 0;
        data.column_names.each_with_index { |f,i| 
          data.column_names[i] = f.to_s.center(max_col_width(i))
        }
        "#{hr}| #{data.column_names.to_a.join(' | ')} |\n"
      end

      action :max_col_width do |index|
        f = data.column_names if data.respond_to? :column_names
        d = Data::Table.new :column_names => f, :data => data
        
        cw = d.map { |r| r[index].to_s.length }.max
        
        return cw unless d.column_names
        
        nw = (index.kind_of?(Integer) ? d.column_names[index] : index ).to_s.length
        
        [cw,nw].max
      end

      action :table_width do
        f = data.column_names if data.respond_to? :column_names
        d = Data::Table.new:column_names => f, :data => data 
        
        f = d[0].attributes || (0...d[0].length)
        f.inject(0) { |s,e| s + max_col_width(e) }
      end

      action :hr do
        len = data[0].to_a.length * 3 + table_width + 1
        "+" + "-"*(len-2) + "+\n"
      end

      attribute :right_margin
      plugin_name :text
      register_on :table_engine
      register_on :document_engine
    end
  end
end

