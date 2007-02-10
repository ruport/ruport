module Ruport::Format
  class SVG < Plugin

    # a hash of Scruffy themes.
    #
    # You can use these by setting options.theme like this:
    #
    #   Graph.render_svg { |r| r.options.theme = r.plugin.themes[:mephisto] }
    #  
    # Available themes: ( :mephisto, :keynote, :ruby_blog )
    #
    def themes
      { :mephisto => Scruffy::Themes::Mephisto.new,
        :keynote  => Scruffy::Themes::Keynote.new,
        :ruby_blog => Scruffy::Themes::RubyBlog.new }
    end

    # generates a scruffy graph object
    def initialize
      require 'scruffy'
      
      @graph = Scruffy::Graph.new
    end

    # the Scruffy::Graph object
    attr_reader :graph

    # sets the graph title, theme, and column_names
    #
    # column_names are defined by the Data::Table,
    # theme may be specified by options.theme (see SVG#themes)
    # title may be specified by options.title 
    #
    def prepare_graph 
      @graph.title ||= options.title
      @graph.theme = options.theme if options.theme
      @graph.point_markers ||= data.column_names

    end

    # Generates an SVG using Scruffy.
    def build_graph
      data.each_with_index do |r,i|
        add_line(r.to_a,r.tags.to_a[0].to_s || "series #{i+1}")
      end

      output << @graph.render(:size => [options.width, options.height])
    end
    
    # Uses Scruffy::Graph#add to add a new line to the graph.
    #
    # Will use the first tag on a Record as the label if present.
    #
    # Line style is determined by options.style
    #
    def add_line(row,label)
      @graph.add( options.style, label, row )
    end

  end
end
