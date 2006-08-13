# The Ruport Data Collections.
# Authors: Gregory Brown / Dudley Flanders
#
# This is Free Software.  For details, see LICENSE and COPYING
# Copyright 2006 by respective content owners, all rights reserved.
require 'set'

module Ruport::Data
  class Set < Collection
    
    def initialize(options={})
      @data = ::Set.new
      options[:data].each {|e| self << e} if options[:data]
    end
    
    def <<(other)
      case other
        when Record 
          @data << other
        when Array
          @data << Record.new(other)
      end
    end
    
    def dup
     a =  self.class.new(:data=>@data)
     a.tags = tags.dup
     return a
    end
    alias_method :clone, :dup

    def ==(other)
      @data == other.data
    end
    
    def |(other)
      Set.new :data => (@data | other.data)
    end
    alias_method :union, :|
    
    def &(other)
      Set.new :data => (@data & other.data)
    end
    alias_method :intersection, :&
    
    # Set difference
    def -(other)
      Set.new :data => (@data - other.data)
    end
    alias_method :difference, :-
    
    def_delegators :@data, :each
  end
end
