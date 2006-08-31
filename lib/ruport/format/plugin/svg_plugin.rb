module Ruport
  class Format::Plugin
    class SVGPlugin < Format::Plugin
      helper(:init_plugin) { |eng|
        # check the supplied data can be used for graphing
        data.each { |r|
          if data.column_names.size != r.data.size
            raise InvalidGraphDataError, 
            "Column names and data do not match"           
          end 
          r.data.each { |c|
            begin
              c = BigDecimal.new(c) unless c.kind_of?(Float) || 
                c.kind_of?(Fixnum) || c.kind_of?(BigDecimal)
            rescue
              raise InvalidGraphDataError, 
              "Unable to convert #{c.to_s} into a number" 
            end
          }
        }
        
        raise InvalidGraphOptionError, 
        'You must provide a width before rendering a graph' if eng.width.nil?
        raise InvalidGraphOptionError, 
        'You must provide a height before rendering a graph' if eng.height.nil?
        raise InvalidGraphOptionError, 
        'You must provide a style before rendering a graph' if eng.style.nil?
        if eng.style != :area && eng.style != :bar &&
                                 eng.style != :line &&
                                 eng.style != :smiles &&
                                 eng.style != :stacked 
          raise InvalidGraphOptionError, 'Invalid graph style'
        end

        require 'scruffy'
        @graph = Scruffy::Graph.new
        @graph.title = eng.title unless eng.title.nil?
        @graph.theme = Scruffy::Themes::Mephisto.new  
        @graph.point_markers = @data.column_names  
        @graph_style = eng.style
        @graph_width = eng.width
        @graph_height = eng.height
      }

      renderer :graph do
        
        data.each_with_index { |r,i|
          @graph.add(@graph_style, 
                     r.tags[0] || 'series ' + (i+1).to_s, 
                     r.data)
        }
        
        # return the rendered graph
        @graph.render(:size => [@graph_width, @graph_height])
      end
      
      plugin_name :svg
      register_on :graph_engine
    end
  end
end
