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

    include Taggable
    include Enumerable  
    
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

    def [](index)
      case(index)
      when Integer
        @data[@attributes[index]]
      else
        @data[index]
      end
    end

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

    def to_a
      @attributes.map { |a| @data[a] }
    end
       
     attr_reader :data

    def to_h
      @data.dup
    end          
    
    #alias_method :data,:to_a

    def attributes
      @attributes.dup
    end

    attr_writer :attributes

    def ==(other)
       @attributes.eql?(other.attributes) &&
       to_a == other.to_a
    end
    alias_method :eql?, :==

    def each 
      to_a.each { |e| yield(e) }
    end
      
    def reorder!(*indices)
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

    def reorder(*indices)
      dup.reorder!(*indices)
    end     
          
    def rename_attribute(old_name,new_name,update_index=true)
      @attributes[@attributes.index(old_name)] = new_name if update_index
      @data[new_name] = @data.delete(old_name)
    end

    def hash
      @attributes.hash + to_a.hash
    end

    def dup
      r = Record.new(@data.dup,:attributes => @attributes.dup)
    end

    def method_missing(id,*args)
      k = id.to_s.gsub(/=$/,"")
      if(key = @attributes.find { |r| r.to_s.eql?(k) })
        args[0] ? @data[key] = args[0] : @data[key]
      else
       super
     end
    end 
    
    private
    
    def delete(key)
      @data.delete(key)
    end
  end

end
