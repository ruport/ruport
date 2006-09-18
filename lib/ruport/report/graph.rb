module Ruport
  class Report
    module Graph
      def build_graph
        a = Ruport::Format.graph_object :plugin => :svg
        yield(a); return a
      end

      def render_graph(&block)
        build_graph(&block).render
      end
    end
  end
end
