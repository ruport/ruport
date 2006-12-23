module Ruport
  class Report
    module Graph #:nodoc:
      def build_graph
        a = Ruport::Renderer::Graph.build(:svg)
        yield(a); return a
      end

      def render_graph(&block)
        build_graph(&block).run
      end
    end
  end
end
