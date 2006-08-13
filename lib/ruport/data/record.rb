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
        @attributes = options[:attributes]
      end
    end
    
    # The underlying data which is being stored in the record
    attr_reader :data
    
    def_delegators :@data,:each, :length
  
    def [](index)
      if index.kind_of? Integer
        raise unless index < @data.length
        @data[index]
      else
        @data[@attributes.index(index)]
      end
    end

    def []=(index, value)
      if index.kind_of? Integer
        @data[index] = value
      else
        @data[attributes.index(index)] = value
      end
    end

    def ==(other)
      return false if @attributes && !other.attributes
      return false if other.attributes && !@attributes
      @attributes == other.attributes && @data == other.data
    end

    alias_method :eql?, :==
    
    def to_a; @data.dup; end
    
    def to_h; Hash[*@attributes.zip(data).flatten] end

    def attributes; @attributes && @attributes.dup; end

    def attributes=(a); @attributes=a; end

    def reorder(*indices)
      dup.reorder! *indices
    end

    def reorder!(*indices)
      indices = indices[0] if indices[0].kind_of?(Array) 
      indices.each do |i| 
        self[i] rescue raise ArgumentError, 
                "you may have specified an invalid column" 
      end
      @data = indices.map { |i| self[i] }
      if @attributes
        if indices.all? { |e| e.kind_of? Integer }
          @attributes = indices.map { |i| @attributes[i] }
        else
          @attributes = indices
        end
      end; self
    end


    def dup
      copy = self.class.new(@data,:attributes => attributes)
      copy.tags = self.tags.dup
      return copy
    end 
    
    #FIXME: This does not take into account frozen / tainted state
    alias_method :clone, :dup

    def hash
      (attributes.to_a + data.to_a).hash
    end

    def method_missing(id,*args)
      id = id.to_s.gsub(/=$/,"")
      if @attributes.include?(id)
        args.empty? ? self[id] : self[id] = args.first
      else
        super
      end
    end

  end
end
