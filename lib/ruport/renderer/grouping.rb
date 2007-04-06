module Ruport
  
  # This class implements the basic renderer for a single group of data.
  #
  # == Supported Formatters 
  #
  # * Formatter::CSV
  # * Formatter::Text
  # * Formatter::HTML
  # * Formatter::PDF
  #
  # == Default layout options 
  #
  # * <tt>show_table_headers</tt> #=> true
  #
  # == Formatter hooks called (in order)
  #
  # * build_group_header
  # * build_group_body
  # * build_group_footer
  #
  class Renderer::Group < Renderer

    option :show_table_headers

    options { |o| o.show_table_headers = true }

    stage :group_header
    stage :group_body
    stage :group_footer
  end

  # This class implements the basic renderer for data groupings in Ruport
  # (a collection of Groups).
  #
  # == Supported Formatters 
  #
  # * Formatter::CSV
  # * Formatter::Text
  # * Formatter::HTML
  # * Formatter::PDF
  #
  # == Default layout options 
  #
  # * <tt>show_group_headers</tt> #=> true
  # * <tt>style</tt> #=> :inline
  #
  # == Formatter hooks called (in order)
  #
  # * build_grouping_header
  # * build_grouping_body
  # * build_grouping_footer
  # * finalize_grouping
  #
  class Renderer::Grouping < Renderer

    option :show_group_headers, :style

    options do |o| 
      o.show_group_headers = true 
      o.style = :inline
    end

    stage :grouping_header
    stage :grouping_body
    stage :grouping_footer
    
    finalize :grouping
  end
  
end

