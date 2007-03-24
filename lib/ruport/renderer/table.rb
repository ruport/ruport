# renderer/table.rb : Tabular data renderer for Ruby Reports
#
# Written by Gregory Brown, December 2006.  Copyright 2006, All Rights Reserved
# This is Free Software, please see LICENSE and COPYING for details.

module Ruport

  # This class implements the basic renderer for table rows.
  #
  # == Supported Formatters 
  #  
  # * Formatter::CSV
  # * Formatter::Text
  # * Formatter::HTML
  #
  # == Formatter hooks called (in order)
  #  
  # * build_row
  #
  class Renderer::Row < Renderer
    add_formats :csv, :text, :html 
    option :format_options
    stage :row
  end

  # This class implements the basic tabular data renderer for Ruport.
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
  # * prepare_table
  # * build_table_header
  # * build_table_body
  # * build_table_footer
  # * finalize_table
  #
  class Renderer::Table < Renderer
     
    add_formats :csv, :text, :html, :pdf

    option :show_table_headers, :format_options

    options { |o| o.show_table_headers = true }

    prepare :table
    
    stage :table_header, :table_body, :table_footer

    finalize :table
  end
end
