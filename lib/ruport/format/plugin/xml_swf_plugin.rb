module Ruport
  class Format::Plugin
    class XmlSwfPlugin < Format::Plugin

      helper(:init_plugin) { |eng|
        @chart_type = eng.style.to_s || "bar"
      }

      renderer :graph do

        require_gem "builder"
        builder = Builder::XmlMarkup.new(:indent => 2)
        builder.chart do |b| 
          
          b.chart_type(@chart_type) 
          
          b.chart_data do |cd|
            
            cd.row { |first|
              first.null
              data.column_names.each { |c| first.string(c) }
            }
            
            data.each_with_index { |r,i|
              label = r.tags[0] || "Region #{i}"
              cd.row { |data_row|
                data_row.string(label)
                r.each { |e| data_row.number(e) }
              }
            }
            
          end             
        end
      end

      plugin_name :xml_swf
      register_on :graph_engine

    end
  end
end
