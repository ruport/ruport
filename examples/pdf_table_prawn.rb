$: << File.join(File.dirname(__FILE__), '..', 'lib')

require "ruport"

table = Ruport::Data::Table.new(
          :column_names => %w(Make Model Year Class),
          :data => [
            %w(Nissan Skyline 1989 B),
            %w(Mercedes-Benz 500SL 2005 A),
            %w(Kia Sinatra 2008 C)
        ])

pdf_options = { :pdf_format => {
                  :page_layout => :portrait,
                  :page_size => "LETTER",
                  },
                :table_format => {
                  :cell_style => { :size => 8},
                  :row_colors => ["FFFFFF","F0F0F0"], 
                  :column_widths => {
                    0 => 100,
                    1 => 100,
                    2 => 50,
                    3 => 40
                    }                    
                  },
                :file => 'pdf_table_prawn.pdf'
                }

table.to_prawn_pdf(pdf_options)