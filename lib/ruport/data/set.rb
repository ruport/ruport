# The Ruport Data Collections.
# Authors: Gregory Brown / Dudley Flanders
#
# This is Free Software.  For details, see LICENSE and COPYING
# Copyright 2006 by respective content owners, all rights reserved.
require 'set'

module Ruport::Data
  
  #
  # This class is one of the core classes for building and working with data 
  # in Ruport. The idea is to get your data into a standard form, regardless 
  # of its source (a database, manual arrays, ActiveRecord, CSVs, etc.).
  # 
  # Set is intended to be used as the data store for unstructured data -
  # Ruport::Data::Table is an alternate data store intended for structured, 
	# tabular data.
  #
  # Once your data is in a Ruport::Data::Set object, it can be manipulated
  # to suit your needs, then used to build a report.
  #
  class Set < Collection
    
    #
    # Creates a new Set containing the elements of <tt>options[:data]</tt>.
    #
    # Example:
    #
    #   Set.new :data => [%w[one two three] %w[1 2 3] %w[I II III]]
    #
    def initialize(options={})
      @data = ::Set.new
      options[:data].each {|e| self << e} if options[:data]
    end
    
    #
    # Adds the given object to the Set and returns self. 
    #
    # Example:
    #
    #   set = Set.new :data => [%w[one two three]]
    #   set << [5,6,7]
    #
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
    
    #
    # Produces a shallow copy of the Set: the same data elements are 
    # referenced by both the old and new Sets.
    #
    # Example:
    #
    #   set = Set.new :data => [%w[one two three]]
    #   set2 = set.dup
    #   set == set2 #=> true
    #   set << [8,9,10]
    #   set == set2 #=> false
    #
    def dup
     a =  self.class.new(:data=>@data)
     a.tags = tags.dup
     return a
    end
    alias_method :clone, :dup

    #
    # Two Sets are equal if they contain the same set of objects.
    # 
    # Example:
    #   s1 = Set.new :data => [[1,2,3]]
    #   s2 = Set.new :data => [[1,2,3]]
    #   s1 == s2 #=> true
    #
    def ==(other)
      @data == other.data
    end
    
    # Returns a new Set containing the all of the objects contained in either 
    # of the two Sets.
    #
    # Example:
    #
    #   s1 = Set.new :data => [[1,2,3]]
    #   s2 = Set.new :data => [[4,5,6]]
    #   s3 = s1 | s2
    #   s4 = Set.new :data => [[1,2,3], [4,5,6]]
    #   s3 == s4 #=> true
    #
    def |(other)
      Set.new :data => (@data | other.data)
    end
    alias_method :union, :|
    alias_method :+, :|
    
    #
    # Returns a new Set containing the objects common to the two Sets.
    #
    # Example:
    #
    #   s1 = Set.new :data => [%w[a b c],[1,2,3]]
    #   s2 = Set.new :data => [%w[a b c],[4,5,6]]
    #   s3 = s1 & s2
    #   s4 = Set.new :data => [%w[a b c]]
    #   s3 == s4 #=> true
    #
    def &(other)
      Set.new :data => (@data & other.data)
    end
    alias_method :intersection, :&
    
    #
    # Returns a new Set containing those objects present in this Set but not 
    # the other.
    #
    # Example:
    #
    #   s1 = Set.new :data => [%w[a b c],[1,2,3]]
    #   s2 = Set.new :data => [%w[a b c],[4,5,6]]
    #   s3 = s1 - s2 
    #   s4 = Set.new :data => [[1, 2, 3]]
    #   s3 == s4 #=> true 
    #
    def -(other)
      Set.new :data => (@data - other.data)
    end
    alias_method :difference, :-

    #
    # Returns a new Set containing those objects that are either in this Set 
    # or the other Set but not in both.
    #
    # Example:
    # 
    #   s1 = Set.new :data => [%w[a b c],[1,2,3]]
    #   s2 = Set.new :data => [%w[a b c],[4,5,6]]
    #   s3 = s1 ^ s2
    #   s4 = Set.new :data => [[1, 2, 3],[4,5,6]]
    #   s3 == s4 #=> true   
    #
    def ^(other)
      Set.new :data => (@data ^ other.data)
    end
    
    def_delegators :@data, :each
  end
end
