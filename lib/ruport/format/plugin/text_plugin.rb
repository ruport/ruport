module Ruport
  class Format::Plugin
    class TextPlugin < Format::Plugin
      rendering_options :erb_enabled => true, :red_cloth_enabled => false

      renderer :document
      
      renderer :table do 
        require "ruport/system_extensions" 
        
        return "" if data.length == 0; 

        calculate_max_col_widths

        width = self.right_margin || SystemExtensions.terminal_width

        s = "#{rendered_field_names}#{hr}"
  
        data.each { |r|
          line = Array.new
          r.each_with_index { |f,i|
            line << f.to_s.center(max_col_width[i])
          }
          s += "| #{line.join(' | ')} |\n"
        }
        s += hr

        s.split("\n").each { |r|
           r.gsub!(/\A.{#{width+1},}/) { |m| m[0,width-2] + ">>" }
        }.join("\n") + "\n"
        
      end
      
      format_field_names do
        return "" if data.length == 0
        calculate_max_col_widths
        c=data.column_names.dup
        c.each_with_index { |f,i| 
          c[i] = f.to_s.center(max_col_width[i])
        }
        "#{hr}| #{c.to_a.join(' | ')} |\n"
      end

      action :max_col_width do
        @max_col_width
      end

      action :calculate_max_col_widths do
        @max_col_width=Array.new
        if defined?(data.column_names)
          data.column_names.each_index do |i| 
            @max_col_width[i] = data.column_names[i].to_s.length
          end
        end
            
        data.each {|r|
          r.each_with_index { |f,i|
            if !max_col_width[i] || f.to_s.length > max_col_width[i]
              max_col_width[i] = f.to_s.length
            end
          }
        }
      end

      action :hr do
        len = max_col_width.inject(data[0].to_a.length * 3) {|s,e| s+e} + 1
        "+" + "-"*(len-2) + "+\n"
      end

      attribute :right_margin
      plugin_name :text
      register_on :table_engine
      register_on :document_engine
    end
  end
end

