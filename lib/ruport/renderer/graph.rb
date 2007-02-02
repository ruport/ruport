# renderer/graph.rb
# Generalized graphing support for Ruby Reports
#
# Written by Gregory Brown, Copright December 2006, All Rights Reserved.
#
# This is free software.  See LICENSE and COPYING for details.

module Ruport
  
  # This class implements the basic graphing engine for Ruport.
  #
  # == Supported Format Plugins
  # 
  # * Format::XML
  # * Format::SVG
  #
  # == Default layout options
  #
  # * height #=> 350
  # * width  #=> 500
  # * style  #=> :line
  #
  # ==  Plugin hooks called (in order)
  # 
  # * prepare_graph
  # * build_graph
  # * finalize_graph
  class Renderer::Graph < Renderer

    include Renderer::Helpers

    add_formats :svg,:xml

    layout do |l|
      l.height = 350
      l.width  = 500
      l.style  = :line
    end

    prepare :graph

    stage :graph

    finalize :graph

  end

end
