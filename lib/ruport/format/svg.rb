module Ruport::Format
  class SVG < Plugin


    def themes
      { :mephisto => Scruffy::Themes::Mephisto.new,
        :keynote  => Scruffy::Themes::Keynote.new,
        :ruby_blog => Scruffy::Themes::RubyBlog.new }
    end

    def initialize
      require 'scruffy'
      
      @graph = Scruffy::Graph.new
    end

    attr_reader :graph

    def prepare_graph 
      @graph.title ||= options.title
      @graph.theme = layout.theme if layout.theme
      @graph.point_markers ||= data.column_names

    end

    def build_graph
      data.each_with_index do |r,i|
        add_line(r.to_a,r.tags.to_a[0] || "series #{i+1}")
      end

      output << @graph.render(:size => [layout.width, layout.height])
    end
    
    def add_line(row,label)
      @graph.add( layout.style, label, row )
    end

  end
end
