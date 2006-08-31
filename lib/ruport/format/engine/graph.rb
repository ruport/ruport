module Ruport
  class Format::Engine
    class Graph < Format::Engine
      
      attributes [:width, :height, :style, :title]

      renderer do
        super
        active_plugin.render_graph
      end
    
      alias_engine Graph, :graph_engine
      Ruport::Format.build_interface_for Graph, :graph
    
    end
  end
end
   
