# The Ruport Data Collections.
# Authors: Gregory Brown / Dudley Flanders
#
# This is Free Software.  For details, see LICENSE and COPYING
# Copyright 2006 by respective content owners, all rights reserved.
require 'set'

module Ruport::Data
  class Set < Collection
    
    # Creates a new set containing the elements of options[:data].
    #
    #   Set.new :data => [%w[one two three] %w[1 2 3] %w[I II III]]
    def initialize(options={})
      @data = ::Set.new
      options[:data].each {|e| self << e} if options[:data]
    end
    
    # Adds the given object to the set and returns self.
    #   set = Set.new :data => [%w[one two three]]
    #   set << [5,6,7]
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
    
    # Produces a shallow copy of the set: the same data elements are 
    # referenced by both the old and new sets.
    #
    #   set = Set.new :data => [%w[one two three]]
    #   set2 = set.dup
    #   set == set2 #=> true
    #   set << [8,9,10]
    #   set == set2 #=> false
    def dup
     a =  self.class.new(:data=>@data)
     a.tags = tags.dup
     return a
    end
    alias_method :clone, :dup

    # Equality. Two sets are equal if they contain the same set of objects.
    #   s1 = Set.new :data => [[1,2,3]]
    #   s2 = Set.new :data => [[1,2,3]]
    #   s1 == s2 #=> true
    def ==(other)
      @data == other.data
    end
    
    # Union. Returns a new set containing the union of the objects contained in
    # the two sets.
    #
    #   s1 = Set.new :data => [[1,2,3]]
    #   s2 = Set.new :data => [[4,5,6]]
    #   s3 = s1 | s2
    #   s4 = Set.new :data => [[1,2,3], [4,5,6]]
    #   s3 == s4 #=> true
    def |(other)
      Set.new :data => (@data | other.data)
    end
    alias_method :union, :|
    alias_method :+, :|
    
    # Intersection. Returns a new set containing the objects common to the two
    # sets.
    #
    #   s1 = Set.new :data => [%w[a b c],[1,2,3]]
    #   s2 = Set.new :data => [%w[a b c],[4,5,6]]
    #   s3 = s1 & s2
    #   s4 = Set.new :data => [%w[a b c]]
    #   s3 == s4 #=> true
    def &(other)
      Set.new :data => (@data & other.data)
    end
    alias_method :intersection, :&
    
    # Difference. Returns a new set containing those objects present in this
    # set but not the other.
    #
    #   s1 = Set.new :data => [%w[a b c],[1,2,3]]
    #   s2 = Set.new :data => [%w[a b c],[4,5,6]]
    #   s3 = s1 - s2 
    #   s4 = Set.new :data => [[1, 2, 3]]
    #   s3 == s4 #=> true 
    def -(other)
      Set.new :data => (@data - other.data)
    end
    alias_method :difference, :-

    # Exclusion. Returns a new set containing those objects in this set or the
    # other set but not in both.
    # 
    #   s1 = Set.new :data => [%w[a b c],[1,2,3]]
    #   s2 = Set.new :data => [%w[a b c],[4,5,6]]
    #   s3 = s1 ^ s2
    #   s4 = Set.new :data => [[1, 2, 3],[4,5,6]]
    #   3 == s4 #=> true   
    def ^(other)
      Set.new :data => (@data ^ other.data)
    end
    
    def_delegators :@data, :each
  end
end
