module Ruport
  module Format
    class Text < Plugin

      def prepare_table
        raise "Can't output empty table" if data.empty?
        calculate_max_col_widths
      end

      def build_table_header
        return if data.column_names.empty? || !layout.show_table_headers
        c = data.column_names.dup
        c.each_with_index { |f,i|
          c[i] = f.to_s.center(layout.max_col_width[i])
        }
        output << fit_to_width("#{hr}| #{c.to_a.join(' | ')} |\n")
      end

      def build_table_body
        s = hr
  
        data.each { |r|
          line = Array.new
          r.each_with_index { |f,i|
            line << f.to_s.center(layout.max_col_width[i])
          }
          s += "| #{line.join(' | ')} |\n"
        }
        s += hr

        output << fit_to_width(s)
      end

      def hr
        len = layout.max_col_width.inject(data[0].to_a.length * 3) {|s,e|s+e}+1
        "+" + "-"*(len-2) + "+\n"
      end

      def width
        require "ruport/system_extensions"
        layout.table_width || SystemExtensions.terminal_width
      end

      def fit_to_width(s)
        s.split("\n").each { |r|
           r.gsub!(/\A.{#{width+1},}/) { |m| m[0,width-2] + ">>" }
        }.join("\n") + "\n"
      end

      def calculate_max_col_widths
        # allow override
        return if layout.max_col_width

        layout.max_col_width=Array.new
        unless data.column_names.empty?
          data.column_names.each_index do |i| 
            layout.max_col_width[i] = data.column_names[i].to_s.length
          end
        end
            
        data.each { |r|
          r.each_with_index { |f,i|
            if !layout.max_col_width[i] || f.to_s.length > layout.max_col_width[i]
              layout.max_col_width[i] = f.to_s.length
            end
          }
        } 
      end

    end
  end
end
