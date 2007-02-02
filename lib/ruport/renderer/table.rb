# renderer/table.rb : Tabular data renderer for Ruby Reports
#
# Written by Gregory Brown, December 2006.  Copyright 2006, All Rights Reserved
# This is Free Software, please see LICENSE and COPYING for details.

module Ruport
  #
  # This module provides some additional methods for Renderer::Table that may be
  # helpful when rendering tabular data.
  #
  # These methods assume you are working with Data::Table objects
  module Renderer::TableHelpers

    # Allows you to modify a column at rendering time based on a block.
    # This will not effect the original data object you provided to the table
    # renderer
    #
    # Example:
    #
    #   table.as(:text){ |r| r.rewrite_column("col1") { |a| a[0] + 5 }
    #   table.as(:csv) { |r| r.rewrite_column(2) { |a| a.capitalize }
    def rewrite_column(key,&block)
      data.to_a.each { |r| r[key] = block[r] }
    end

    # Gets the number of columns in a table.  Useful in formatting plugins.
    def num_cols
      data[0].to_a.length
    end

    # Allows you to remove duplicates from data tables.
    #
    # By default, it will try to prune the entire table, but you may provide a
    # limit of how many columns in it should work.
    #
    # Examples:
    #
    #   irb(main):014:0> puts a
    #    +-----------+
    #    | a | b | c |
    #    +-----------+
    #    | 1 | 2 | 3 |
    #    | 1 | 2 | 2 |
    #    | 1 | 3 | 5 |
    #    | 2 | 7 | 9 |
    #    | 2 | 8 | 3 |
    #    | 2 | 7 | 1 |
    #    | 1 | 7 | 9 |
    #    +-----------+
    #    => nil
    #    irb(main):015:0> puts a.as(:text) { |e| e.prune(2) }
    #    +-----------+
    #    | a | b | c |
    #    +-----------+
    #    | 1 | 2 | 3 |
    #    |   |   | 2 |
    #    |   | 3 | 5 |
    #    | 2 | 7 | 9 |
    #    |   | 8 | 3 |
    #    |   | 7 | 1 |
    #    | 1 | 7 | 9 |
    #    +-----------+
    #    => nil
    #    irb(main):016:0> puts a.as(:text) { |e| e.prune(1) }
    #    +-----------+
    #    | a | b | c |
    #    +-----------+
    #    | 1 | 2 | 3 |
    #    |   | 2 | 2 |
    #    |   | 3 | 5 |
    #    | 2 | 7 | 9 |
    #    |   | 8 | 3 |
    #    |   | 7 | 1 |
    #    | 1 | 7 | 9 |
    #    +-----------+
    def prune(limit=data[0].length)
      require "enumerator"
      limit.times do |field|
        last = ""
        data.each_cons(2) { |l,e|
          next if field.nonzero? && e[field-1] 
          last = l[field] if l[field]
          e[field] = nil if e[field] == last
        }
      end
    end

  end
  
  # This class implements the basic tabular data renderer for Ruport.
  #
  # For a set of methods that might be helpful while working with this class,
  # see the included TableHelpers module
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
  # * <tt>show_table_headers</tt> #=> true
  #
  # == Plugin hooks called (in order)
  #  
  # * prepare_table
  # * build_table_header
  # * build_table_body
  # * build_table_footer
  # * finalize_table
  #
  class Renderer::Table < Renderer
    include TableHelpers
    include Renderer::Helpers
     
    add_formats :csv, :text, :html, :latex, :pdf

    layout { |lay| lay.show_table_headers = true }

    prepare :table
    
    stage :table_header
    stage :table_body
    stage :table_footer

    finalize :table
  end
end
