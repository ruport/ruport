module Ruport::Data
  class Record
    require "forwardable"
    extend Forwardable
    extend Taggable
    
    include Enumerable

    def initialize(data,options={})
      @data = data
      @collection = options[:collection]
      extend Taggable
    end

    attr_reader :data
    def_delegators :@data,:each

  
    def [](index)
      if index.kind_of? Integer
        @data[index]
      else
        @data[@collection.column_names.index(index)]
      end
    end

    def []=(index, value)
      if index.kind_of? Integer
        @data[index] = value
      else
        @data[@collection.column_names.index(index)] = value
      end
    end

    def ==(other)
      return false if column_names && !other.column_names
      return false if other.column_names && !column_names
      (column_names == other.column_names) && (data == other.data)
    end

    alias_method :eql?, :==
    
    def to_a; data.dup; end
    
    def to_h
      column_names.inject({}) { |s,r| s.merge(r => self[r]) } 
    end

    def column_names
      @collection && @collection.column_names
    end

    def method_missing(id,*args)
      id = id.to_s.gsub(/=$/,"")
      if @collection.column_names.include?(id)
        args.empty? ? self[id] : self[id] = args.first
      else
        super
      end
    end

  end
end
