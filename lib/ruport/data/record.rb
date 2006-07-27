module Ruport::Data
  class Record
    require "forwardable"
    extend Forwardable
    include Enumerable
    include Taggable

    def initialize(data,options={})
      @data = data.dup
      @attributes = options[:attributes]
    end

    attr_reader :data
    def_delegators :@data,:each, :length
  
    def [](index)
      if index.kind_of? Integer
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
      self.class.new(@data,:attributes => attributes)
    end 
    
    #FIXME: This does not take into account frozen / tainted state
    alias_method :clone, :dup

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
