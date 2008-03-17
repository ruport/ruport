# Ruport : Extensible Reporting System
#
# data/record.rb provides a record data structure for Ruport.
# 
# Created by Gregory Brown / Dudley Flanders, 2006
# Copyright (C) 2006 Gregory Brown / Dudley Flanders, All Rights Reserved.  
#
# This is free software distributed under the same terms as Ruby 1.8
# See LICENSE and COPYING for details.   
#
module Ruport::Data

  # === Overview
  # 
  # Data::Records are the work-horse of Ruport's data model. These can behave
  # as Array-like, Hash-like, or Struct-like objects.  They are used as the 
  # base element for Data::Table
  #
  class Record   
    
    if RUBY_VERSION < "1.9"
      private :id     
    end

    include Enumerable  
    
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
    
    ##############
    # Delegators #
    ##############
    
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
    
    # Sets the <tt>attribute</tt> list for this Record. 
    # (Dangerous when used within Table objects!)
    attr_writer :attributes        
 
    # The data for the record
    attr_reader :data
    
    # The size of the record (the number of items in the record's data).
    def size; @data.size; end
    alias_method :length, :size
    
    ##################
    # Access Methods #
    ##################
    
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
        @attributes << index unless @attributes.include? index
      end
    end
    
    # Indifferent access to attributes.
    #  
    # Examples:
    #          
    #   record.get(:foo) # looks for an attribute "foo" or :foo,
    #                      or calls the method <tt>foo</tt>
    #
    #   record.get("foo") # looks for an attribute "foo" or :foo
    #
    #   record.get(0) # Gets the first element
    #
    def get(name)
      case name
      when String,Symbol
        self[name] || send(name)
      when Fixnum
        self[name]
      else
        raise ArgumentError, "Whatchu Talkin' Bout, Willis?"
      end
    end          
    
    ################
    #  Conversions #
    ################
    
    # Converts a Record into an Array.
    #
    # Example:
    #
    #   a = Data::Record.new([1,2],:attributes => %w[a b])
    #   a.to_a #=> [1,2]
    #
    def to_a
      @attributes.map { |a| @data[a] }
    end
         
    # Converts a Record into a Hash. 
    #
    # Example:
    #
    #   a = Data::Record.new([1,2],:attributes => %w[a b])
    #   a.to_hash #=> {"a" => 1, "b" => 2}
    #
    def to_hash
      @data.dup
    end
        
    ################
    #  Comparisons #
    ################
    
    # If <tt>attributes</tt> and <tt>to_a</tt> are equivalent, then 
    # <tt>==</tt> evaluates to true. Otherwise, <tt>==</tt> returns false.
    #
    def ==(other)
       @attributes.eql?(other.attributes) &&
       to_a == other.to_a
    end
    
    alias_method :eql?, :==
    
    #############
    # Iterators #
    #############
    
    # Yields each element of the Record.  Does not provide attribute names.
    def each 
      to_a.each { |e| yield(e) }
    end   
    
    #################
    # Manipulations #
    ################# 
    
    # Takes an old name and a new name and renames an attribute.  
    #
    # The third option, update_index is for internal use.    
    def rename_attribute(old_name,new_name,update_index=true)
      @attributes[@attributes.index(old_name)] = new_name if update_index
      @data[new_name] = @data.delete(old_name)
    end
    
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
       
    ####################### 
    # Internals / Helpers #
    #######################       

    include Ruport::Controller::Hooks
    renders_as_row

    def self.inherited(base) #:nodoc:
      base.renders_as_row
    end

    # Provides a unique hash value. If a Record contains the same data and
    # attributes as another Record, they will hash to the same value, even if
    # they are not the same object. This is similar to the way Array works, 
    # but different from Hash and other objects.
    #
    def hash
      @attributes.hash + to_a.hash
    end
    
    # Create a copy of the Record.
    #
    # Example:
    #
    #   one = Record.new([1,2,3,4],:attributes => %w[a b c d])
    #   two = one.dup
    #
    def initialize_copy(from) #:nodoc:
       @data = from.data.dup
       @attributes = from.attributes.dup
    end

    # Provides accessor style methods for attribute access.
    #
    # Example:
    #
    #   my_record.foo = 2
    #   my_record.foo #=> 2
    #
    # Also provides a shortcut for the <tt>as()</tt> method by converting a
    # call to <tt>to_format_name</tt> into a call to <tt>as(:format_name)</tt>
    #
    def method_missing(id,*args,&block)
      k = id.to_s.gsub(/=$/,"")
      key_index = @attributes.index(k) || @attributes.index(k.to_sym)

      if key_index
        args[0] ? self[key_index] = args[0] : self[key_index]
      else
        return as($1.to_sym,*args,&block) if id.to_s =~ /^to_(.*)/ 
        super
      end
    end 
    
    private
    
    def delete(key)
      @data.delete(key)
      @attributes.delete(key)
    end

    def reindex(new_attributes)
      @attributes = new_attributes
    end
  end
end
