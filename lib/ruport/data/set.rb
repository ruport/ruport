# The Ruport Data Collections.
# Authors: Gregory Brown / Dudley Flanders
#
# This is Free Software.  For details, see LICENSE and COPYING
# Copyright 2006 by respective content owners, all rights reserved.
require 'set'

module Ruport::Data
  class Set < Collection
    
    # Creates a new set containing the elements of options[:data].
    def initialize(options={})
      @data = ::Set.new
      options[:data].each {|e| self << e} if options[:data]
    end
    
    # Adds the given object to the set and returns self.
    def add(other)
      case other
        when Record 
          @data << other
        when Array
          @data << Record.new(other)
      end
      self
    end
    alias_method :<<, :add
    
    # Produces a shallow copy of the set: the same data is referenced by both
    # the old and new sets.
    def dup
     a =  self.class.new(:data=>@data)
     a.tags = tags.dup
     return a
    end
    alias_method :clone, :dup

    # Equality. Two sets are equal if they contain the same set of objects.
    def ==(other)
      @data == other.data
    end
    
    # Union. Returns a new set containing the union of the objects contained in
    # the two sets.
    def |(other)
      Set.new :data => (@data | other.data)
    end
    alias_method :union, :|
    alias_method :+, :|
    
    # Intersection. Returns a new set containing the objects common to the two
    # sets.
    def &(other)
      Set.new :data => (@data & other.data)
    end
    alias_method :intersection, :&
    
    # Difference. Returns a new set containing those objects present in this
    # set but not the other.
    def -(other)
      Set.new :data => (@data - other.data)
    end
    alias_method :difference, :-

    # Exclusion. Returns a new set containing those objects in this set or the
    # other set but not in both.
    def ^(other)
      Set.new :data => (@data ^ other.data)
    end
    
    def_delegators :@data, :each
  end
end
