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
  # base element for Data::Table
  #
  class Record

    include Taggable
    include Enumerable  
    
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
    #   c[1]   #=> 2
    #   c['a'] #=> 1
    #   c.c    #=> 3
    #
    #   d = Record.new { "a" => 1, "c" => 3, "b" => 2 }
    #   d[1]   #=> ? (without attributes, you cannot rely on order)
    #   d['a'] #=> 1
    #   d.c    #=> 3
    #
    def initialize(data,options={})
      data = data.dup
      case(data)
      when Array
        @attributes = options[:attributes] || (0...data.length).to_a
        @data = @attributes.inject({}) { |h,a| h.merge(a => data.shift) }
      when Hash
        @data = data.dup
        @attributes = options[:attributes] || data.keys
      end
    end 
    
    #
    # Allows either Array or Hash-like indexing.
    #
    # Examples:
    #
    #   my_record[1] 
    #   my_record["foo"]
    #
    def [](index)
      case(index)
      when Integer
        @data[@attributes[index]]
      else
        @data[index]
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
    def []=(index,value)
      case(index)
      when Integer
        @data[@attributes[index]] = value
      else
        @data[index] = value
      end
    end

    def size
      @data.size
    end
    alias_method :length, :size
    
    #
    # Converts a Record into an Array.
    #
    # Example:
    #
    #   a = Data::Record.new([1,2],:attributes => %w[a b])
    #   a.to_a #=> [1,2]
    #
    # Note: in earlier versions of Ruport, to_a was aliased to data.
    #       From now on to_a only for array representation! 
    def to_a
      @attributes.map { |a| @data[a] }
    end
       
     attr_reader :data
    
     #
     # Converts a Record into a Hash. 
     #
     # Example:
     #
     #   a = Data::Record.new([1,2],:attributes => %w[a b])
     #   a.to_h #=> {"a" => 1, "b" => 2}
    def to_h
      @data.dup
    end          
    
    #alias_method :data,:to_a
     
    # Returns a copy of the <tt>attributes</tt> from this Record.
    #
    # Example:
    #
    #   a = Data::Record.new([1,2],:attributes => %w[a b])
    #   a.attributes #=> ["a","b"]
    #
    def attributes
      @attributes.dup
    end
    
    #
    # Sets the <tt>attribute</tt> list for this Record. 
    # (Dangerous when used within Table objects!)
    #
    # Example:
    #
    #   my_record.attributes = %w[foo bar baz]
    #
    attr_writer :attributes
    
    #
    # If <tt>attributes</tt> and <tt>to_a</tt> are equivalent, then 
    # <tt>==</tt> evaluates to true. Otherwise, <tt>==</tt> returns false.
    #
    def ==(other)
       @attributes.eql?(other.attributes) &&
       to_a == other.to_a
    end
    
    alias_method :eql?, :==
    
    # Yields each element of the Record.  Does not provide attribute names
    def each 
      to_a.each { |e| yield(e) }
    end
    
    #
    # Allows you to change the order of or reduce the number of columns in a
    # Record.  
    #
    # Example:
    #
    #   a = Data::Record.new([1,2,3,4],:attributes => %w[a b c d])
    #   a.reorder("a","d","b")
    #   a.attributes #=> ["a","d","b"]
    #   a.data #=> [1,4,2]  
    def reorder(*indices)
      indices[0].kind_of?(Array) && indices.flatten!
      if indices.all? { |i| i.kind_of? Integer } 
        raise ArgumentError unless indices.all? { |i| @attributes[i] }
        self.attributes = indices.map { |i| @attributes[i] }
      else
        raise ArgumentError unless (indices - @attributes).empty?
        self.attributes = indices
      end
      self
    end  
     
    # Takes an old name and a new name and renames an attribute.      
    def rename_attribute(old_name,new_name,update_index=true)
      @attributes[@attributes.index(old_name)] = new_name if update_index
      @data[new_name] = @data.delete(old_name)
    end
    
    #
    # Provides a unique hash value. If a Record contains the same data and
    # attributes as another Record, they will hash to the same value, even if
    # they are not the same object. This is similar to the way Array works, 
    # but different from Hash and other objects.
    #
    def hash
      @attributes.hash + to_a.hash
    end
    
    # Makes a fresh copy of the Record. 
    def dup
      r = Record.new(@data.dup,:attributes => @attributes.dup)
      r.tags = tags.dup
      return r
    end
        
    # A simple formatting tool which allows you to quickly generate a formatted
    # row from the record.
    #
    # If a block is given, the Renderer::Row object will be yielded
    #
    # Example:
    #   my_record.as(:csv)  #=> "1,2,3\n"
    #   
    def as(*args)
      Ruport::Renderer::Row.render(*args) do |rend|
        rend.data = self
        yield(rend) if block_given?
      end
    end

    # Provides accessor style methods for attribute access.
    #
    # Example:
    #
    #   my_record.foo = 2
    #   my_record.foo #=> 2
    #
    def method_missing(id,*args)
      k = id.to_s.gsub(/=$/,"")
      if(key = @attributes.find { |r| r.to_s.eql?(k) })
        args[0] ? @data[key] = args[0] : @data[key]
      else
        return as($1.to_sym) if id.to_s =~ /^to_(.*)/ 
        super
      end
    end 

    #indifferentish access that also can call methods
    def get(name)
      case name
      when Symbol
        send(name)
      when String
        self[name]
      else
        raise "Whatchu Talkin' Bout, Willis?"
      end
    end
    
    private
    
    def delete(key)
      @data.delete(key)
    end


    def reindex(new_attributes)
      @attributes.replace(new_attributes)
    end
  end
end
