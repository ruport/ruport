module Ruport::Format
  class XML < Plugin

    def prepare_graph
      gem "builder"
      @builder = Builder::XmlMarkup.new(:indent => 2)
    end

    def build_graph
      output << @builder.chart do |b|
        b.chart_type(layout.style.to_s)

        b.chart_data do |cd|
          
          cd.row { |first|
            first.null
            data.column_names.each { |c| first.string(c) }
          }

          data.each_with_index { |r,i|
            label = r.tags.to_a[0] || "Region #{i}"
            cd.row { |data_row|
              data_row.string(label)
              r.each { |e| data_row.number(e) }
            }
          }
        end
      end
    end

  end
end
