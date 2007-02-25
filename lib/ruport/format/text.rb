module Ruport
  module Format
    class Text < Plugin
      
      # Checks to ensure the table is not empty and then calls
      # calculate_max_col_widths
      #
      def prepare_table
        raise "Can't output empty table" if data.empty?
        calculate_max_col_widths
      end

      # Uses the column names from the given Data::Table to generate a table
      # header.
      #
      # calls fit_to_width to truncate table heading if necessary.
      def build_table_header
        return unless should_render_column_names

        c = data.column_names.enum_for(:each_with_index).map { |f,i|
          f.to_s.center(options.max_col_width[i])
        }

        output << fit_to_width("#{hr}| #{c.join(' | ')} |\n")
      end

      # Returns false if column_names are empty, or options.show_table_headers
      # is false/nil.  Returns true otherwise.
      #
      def should_render_column_names
        not data.column_names.empty? || !options.show_table_headers
      end

      # Generates the body of the text table. 
      #
      # Defaults to numeric values being right justified, and other values being
      # left justified.  Can be changed to support centering of output by
      # setting options.alignment to :center
      #
      # Uses fit_to_width to truncate table if necessary
      def build_table_body
        output << fit_to_width(hr)
  

        calculate_max_col_widths unless options.max_col_width

        data.each { |r|
          r.as(:text, :io => output,
            :max_col_width => options.max_col_width,
            :alignment => options.alignment,
            :table_width => options.table_width)
        }

        output << fit_to_width(hr)
      end

      def build_row

        max_col_widths_for_row(data) unless options.max_col_width

        data.enum_for(:each_with_index).inject(line=[]) { |s,e|
          field,index = e
          if options.alignment.eql? :center
            line << field.to_s.center(options.max_col_width[index])
          else
            align = field.is_a?(Numeric) ? :rjust : :ljust
            line << field.to_s.send(align, options.max_col_width[index])
          end
        }
        output << fit_to_width("| #{line.join(' | ')} |\n")
      end

      # Generates the horizontal rule by calculating the total table width and
      # then generating a bar that looks like this:
      #
      #   "+------------------+"
      def hr
        len = options.max_col_width.inject(data[0].to_a.length * 3) {|s,e|s+e}+1
        "+" + "-"*(len-2) + "+\n"
      end
      
      # Returns options.table_width if specified.
      #
      # Otherwise, uses SystemExtensions to determine terminal width.
      def width
        require "ruport/system_extensions"
        options.table_width || SystemExtensions.terminal_width
      end

      # Truncates a string so that it does not exceed Text#width
      def fit_to_width(s)
        # workaround for Rails setting terminal_width to 1
        max_width = width < 2 ? 80 : width
        
        s.split("\n").each { |r|
           r.gsub!(/\A.{#{max_width+1},}/) { |m| m[0,max_width-2] + ">>" }
        }.join("\n") + "\n"
      end

      # determines the text widths for each column.
      def calculate_max_col_widths

        # allow override
        return if options.max_col_width

        options.max_col_width = []

        unless data.column_names.empty?
          data.column_names.each_index do |i| 
            options.max_col_width[i] = data.column_names[i].to_s.length
          end
        end
            
        data.each { |r| max_col_widths_for_row(r) } 

      end

      def max_col_widths_for_row(row)
        options.max_col_width ||= []
        row.each_with_index do |f,i|
          if !options.max_col_width[i] || f.to_s.length > options.max_col_width[i]
            options.max_col_width[i] = f.to_s.length
          end
        end
      end

    end
  end
end
