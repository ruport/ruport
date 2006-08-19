# The Ruport Data Collections.
# Authors: Gregory Brown / Dudley Flanders
#
# This is Free Software.  For details, see LICENSE and COPYING
# Copyright 2006 by respective content owners, all rights reserved.

module Ruport::Data
  
  # This is the base class for Ruport's Data structures.
  class Collection
    require "forwardable"
    extend Forwardable
    include Enumerable
    include Taggable

    def initialize(data=nil,options={})
      @data = data.dup if data
    end

    # Simple formatting tool which allows you to quickly generate a formatted
    # table from a Collection object, eg
    #
    # my_collection.as(:csv) #=> "1,2,3\n4,5,6"
    def as(type)
      Ruport::Format.table :data => self, :plugin => type
    end

    # Converts any Collection object to a Data::Set
    def to_set
      Set.new :data => data
    end
   
    # Converts any Collection object to a Data::Table
    def to_table(options={})
      Table.new({:data => data.map { |r| r.to_a }}.merge(options))
    end

    # Provides a shortcut for the as() method by converting as(:format_name)
    # into to_format_name
    def method_missing(id,*args)
     return as($1.to_sym) if id.to_s =~ /^to_(.*)/ 
     super
    end
    
    attr_reader :data
    def_delegators :@data, :each, :length, :size, :[], :empty?
  end
end

