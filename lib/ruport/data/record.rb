# The Ruport Data Collections.
# Authors: Gregory Brown / Dudley Flanders
#
# This is Free Software.  For details, see LICENSE and COPYING
# Copyright 2006 by respective content owners, all rights reserved.
module Ruport::Data

  # Data::Records are the work horse of Ruport's Data model.  These can behave
  # as array like, hash like, or struct like objects.  They are used as the base
  # record for both Tables and Sets in Ruport.
  class Record
    require "forwardable"
    extend Forwardable
    include Enumerable
    include Taggable

    # Creates a new Record object.  If the <tt>:attributes</tt> keyword is
    # specified, Hash-like and Struct-like access will be enabled.  Otherwise,
    # Record elements may be accessed ordinally, like an Array.
    # 
    # Records accept either Hashes or Arrays as their data.
    #
    #   a = Record.new [1,2,3]
    #   a[1] #=> 2
    #
    #   b = Record.new [1,2,3], :attributes => %w[a b c]
    #   b[1]   #=> 2  
    #   b['a'] #=> 1
    #   b.c    #=> 3
    #
    #   c = Record.new {"a" => 1, "c" => 3, "b" => 2}, :attributes => %w[a b c]
    #   b[1]   #=> 2
    #   b['a'] #=> 1
    #   b.c    #=> 3
    #
    #   c = Record.new { "a" => 1, "c" => 3, "b" => 2 }
    #   b[1]   #=> ? (without attributes, you cannot rely on order)
    #   b['a'] #=> 1
    #   b.c    #=> 3
    def initialize(data,options={})
      if data.kind_of?(Hash)
        if options[:attributes]
          @attributes = options[:attributes]
          @data = options[:attributes].map { |k| data[k] }
        else
          @attributes, @data = data.to_a.transpose
        end
      else
        @data = data.dup
        @attributes = options[:attributes] || []
      end
    end
    
    # The underlying data which is being stored in the record
    attr_reader :data
    
    def_delegators :@data,:each, :length
  
    # Allows either array or hash_like indexing
    #
    #   my_record[1] 
    #   my_record["foo"]
    #
    # Also, this provides a feature via method_missing which allows
    #   my_record.foo
    def [](index)
      if index.kind_of? Integer
        raise "Invalid index" unless index < @data.length
        @data[index]
      else
        index = index.to_s
        raise "Invalid index" unless attributes.index(index)
        @data[attributes.index(index)]
      end
    end


    # Allows setting a value at an index
    #  
    #    my_record[1] = "foo" 
    #    my_record["bar"] = "baz"
    #
    # And via method_missing
    #    my_record.ghost = "blinky"
    def []=(index, value)
      if index.kind_of? Integer
        raise "Invalid index" unless index < @data.length
        @data[index] = value
      else
        index = index.to_s
        raise "Invalid index" unless @attributes.index(index)
        @data[attributes.index(index)] = value
      end
    end


    # If attributes and data are equivalent, then == evaluates to true.
    # Otherwise, == returns false
    def ==(other)
      return false if @attributes && !other.attributes
      return false if other.attributes && !@attributes
      @attributes == other.attributes && @data == other.data
    end

    alias_method :eql?, :==
   
    # Makes an array out of the data wrapped by Record
    #
    #   a = Data::Record.new([1,2],:attributes => %w[a b])
    #   a.to_a #=> [1,2]
    def to_a; @data.dup; end
   
    # Makes a hash out of the data wrapped by Record
    # Only works if attributes are specified
    #
    #   a = Data::Record.new([1,2],:attributes => %w[a b])
    #   a.to_h #=> {"a" => 1, "b" => 2}
    def to_h; Hash[*@attributes.zip(data).flatten] end
  
    # Returns a copy of the list of attribute names associated with this Record.
    #
    #   a = Data::Record.new([1,2],:attributes => %w[a b])
    #   a.attributes #=> ["a","b"]
    def attributes; @attributes.map { |a| a.to_s } ; end

    # Sets the attribute list for this Record
    #
    #   my_record.attributes = %w[foo bar baz]
    attr_writer :attributes
    # Allows you to change the order of or reduce the number of columns in a
    # Record.  Example:
    #
    #   a = Data::Record.new([1,2,3,4],:attributes => %w[a b c d])
    #   b = a.reorder("a","d","b")
    #   b.attributes #=> ["a","d","b"]
    #   b.data #=> [1,4,2]
    def reorder(*indices)
      dup.reorder!(*indices)
    end
    
    # Same as Record#reorder but is destructive
    def reorder!(*indices)
      indices = reorder_data!(*indices)
      if @attributes
        if indices.all? { |e| e.kind_of? Integer }
          @attributes = indices.map { |i| @attributes[i] }
        else
          @attributes = indices
        end
      end; self
    end

    def reorder_data!(*indices)
      indices = indices[0] if indices[0].kind_of?(Array) 
      indices.each do |i| 
        self[i] rescue raise ArgumentError, 
                "you may have specified an invalid column" 
      end
      @data = indices.map { |i| self[i] }
      return indices;
    end

    
    # Makes a fresh copy of the Record
    def dup
      copy = self.class.new(@data,:attributes => attributes)
      copy.tags = self.tags.dup
      return copy
    end 
    
    #FIXME: This does not take into account frozen / tainted state
    alias_method :clone, :dup
    
    # provides a unique hash value
    def hash
      (attributes.to_a + data.to_a).hash
    end

    # provides accessor style methods for attribute access, Example
    #
    #   my_record.foo = 2
    #   my_record.foo #=> 2
    def method_missing(id,*args)
      id = id.to_s.gsub(/=$/,"")
      if attributes.include?(id)
        args.empty? ? self[id] : self[id] = args.first
      else
        super
      end
    end

  end
end
