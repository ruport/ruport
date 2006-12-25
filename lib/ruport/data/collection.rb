# The Ruport Data Collections.
# Authors: Gregory Brown / Dudley Flanders
#
# This is Free Software.  For details, see LICENSE and COPYING
# Copyright 2006 by respective content owners, all rights reserved.

module Ruport::Data
  
  #
  # === Overview
  #
  # This is the base class for Ruport's Data structures. It mixes in the 
  # <tt>Taggable</tt> module and provides methods for converting between 
  # <tt>Data::Set</tt>s and <tt>Data::Table</tt>s.
  #
  class Collection
    require "forwardable"
    extend Forwardable
    include Enumerable
    include Taggable
    
    def initialize(data=nil,options={}) #:nodoc:
      @data = data.dup if data
    end

    # A simple formatting tool which allows you to quickly generate a formatted
    # table from a <tt>Collection</tt> object.
    #
    # Example:
    #   my_collection.as(:csv)  #=> "1,2,3\n4,5,6"
    def as(type)
      Ruport::Renderer::Table.render(type) do |rend|
        rend.data = self
        yield(rend) if block_given?
      end
    end

    # Converts a <tt>Collection</tt> object to a <tt>Data::Set</tt>.
    def to_set
      Set.new :data => data
    end
   
    # Converts a <tt>Collection</tt> object to a <tt>Data::Table</tt>.
    def to_table(options={})
      Table.new({:data => data.map { |r| r.to_a }}.merge(options))
    end

    # Provides a shortcut for the <tt>as()</tt> method by converting a call to
    # <tt>as(:format_name)</tt> into a call to <tt>to_format_name</tt>
    def method_missing(id,*args)
     return as($1.to_sym) if id.to_s =~ /^to_(.*)/ 
     super
    end
    
    attr_reader :data
    def_delegators :@data, :each, :length, :size, :empty?
  end
end

