# The Ruport Data Collections.
# Authors: Gregory Brown / Dudley Flanders
#
# This is Free Software.  For details, see LICENSE and COPYING
# Copyright 2006 by respective content owners, all rights reserved.
module Ruport::Data

  #
  # === Overview
  # 
  # Data::Records are the work horse of Ruport's data model. These can behave
  # as Array-like, Hash-like, or Struct-like objects.  They are used as the 
  # base element in both Tables and Sets.
  #
  class Record
    require "forwardable"
    extend Forwardable
    include Enumerable
    include Taggable

    # 
    # Creates a new Record object.  If the <tt>:attributes</tt> 
    # keyword is specified, Hash-like and Struct-like 
    # access will be enabled.  Otherwise, Record elements may be 
    # accessed ordinally, like an Array.
    # 
    # A Record can accept either a Hash or an Array as its <tt>data</tt>.
    #
    # Examples:
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
    #
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
    
    # The underlying <tt>data</tt> which is being stored in the record.
    attr_reader :data
    
    def_delegators :@data,:each, :length
  
    #
    # Allows either Array or Hash-like indexing.
    #
    # Examples:
    #
    #   my_record[1] 
    #   my_record["foo"]
    #
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


    # 
    # Allows setting a <tt>value</tt> at an <tt>index</tt>.
    # 
    # Examples:
    #
    #    my_record[1] = "foo" 
    #    my_record["bar"] = "baz"
    #
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

    #
    # If <tt>attributes</tt> and <tt>data</tt> are equivalent, then 
    # <tt>==</tt> evaluates to true. Otherwise, <tt>==</tt> returns false.
    #
    def ==(other)
      return false if @attributes && !other.attributes
      return false if other.attributes && !@attributes
      @attributes == other.attributes && @data == other.data
    end

    alias_method :eql?, :==
   
    #
    # Converts a Record into an Array.
    #
    # Example:
    #
    #   a = Data::Record.new([1,2],:attributes => %w[a b])
    #   a.to_a #=> [1,2]
    #
    def to_a; @data.dup; end
    
    #
    # Converts a Record into a Hash. This only works if <tt>attributes</tt> 
    # are specified in the Record.
    #
    # Example:
    #
    #   a = Data::Record.new([1,2],:attributes => %w[a b])
    #   a.to_h #=> {"a" => 1, "b" => 2}
    def to_h; Hash[*@attributes.zip(data).flatten] end
  
    #
    # Returns a copy of the <tt>attributes</tt> from this Record.
    #
    # Example:
    #
    #   a = Data::Record.new([1,2],:attributes => %w[a b])
    #   a.attributes #=> ["a","b"]
    #
    def attributes; @attributes.map { |a| a.to_s }; end

    #
    # Sets the <tt>attribute</tt> list for this Record.
    #
    # Example:
    #
    #   my_record.attributes = %w[foo bar baz]
    #
    attr_writer :attributes

    #
    # Allows you to change the order of or reduce the number of columns in a
    # Record.  
    #
    # Example:
    #
    #   a = Data::Record.new([1,2,3,4],:attributes => %w[a b c d])
    #   b = a.reorder("a","d","b")
    #   b.attributes #=> ["a","d","b"]
    #   b.data #=> [1,4,2]
    #
    def reorder(*indices)
      dup.reorder!(*indices)
    end
    
    # Same as Record#reorder but modifies its reciever in place.
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

    def reorder_data!(*indices) # :nodoc:
      indices = indices[0] if indices[0].kind_of?(Array) 
      indices.each do |i| 
        self[i] rescue raise ArgumentError, 
                "you may have specified an invalid column" 
      end
      @data = indices.map { |i| self[i] }
      return indices;
    end

    
    # Makes a fresh copy of the Record.
    def dup
      copy = self.class.new(@data,:attributes => attributes)
      copy.tags = self.tags.dup
      return copy
    end 
    
    #FIXME: This does not take into account frozen / tainted state
    alias_method :clone, :dup
    
    #
    # Provides a unique hash value. If a Record contains the same data and
    # attributes as another Record, they will hash to the same value, even if
    # they are not the same object. This is similar to the way Array works, 
    # but different from Hash and other objects.
    #
    def hash
      (attributes.to_a + data.to_a).hash
    end

    #
    # Provides accessor style methods for attribute access.
    #
    # Example:
    #
    #   my_record.foo = 2
    #   my_record.foo #=> 2
    #
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
