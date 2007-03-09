module Ruport
  
  # This class implements the basic renderer for a single group of data.
  #
  # == Supported Format Plugins 
  #
  # * Format::CSV
  # * Format::Text
  # * Format::HTML
  # * Format::Latex
  # * Format::PDF
  #
  # == Default layout options 
  #
  # * <tt>show_group_headers</tt> #=> true
  #
  # == Plugin hooks called (in order)
  #
  # * build_group_header
  # * build_group_body
  # * build_group_footer
  #
  class Renderer::Group < Renderer
    add_formats :html, :text, :csv#,:pdf, :latex

    option :show_group_headers

    options { |o| o.show_group_headers = true }

    stage :group_header
    stage :group_body
    stage :group_footer
  end

  # This class implements the basic renderer for data groupings in Ruport
  # (a collection of Groups).
  #
  # == Supported Format Plugins 
  #
  # * Format::CSV
  # * Format::Text
  # * Format::HTML
  # * Format::Latex
  # * Format::PDF
  #
  # == Default layout options 
  #
  # * <tt>show_group_headers</tt> #=> true
  #
  # == Plugin hooks called (in order)
  #
  # * build_grouping_header
  # * build_grouping_body
  # * build_grouping_footer
  #
  class Renderer::Grouping < Renderer
    add_formats :csv, :text, :html, :latex, :pdf

    option :show_group_headers

    options { |o| o.show_group_headers = true }

    stage :grouping_header
    stage :grouping_body
    stage :grouping_footer
  end
  
end

