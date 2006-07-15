module Ruport::Data
  class Record
    require "forwardable"
    extend Forwardable
    include Enumerable
    extend Taggable

    def initialize(data,options={})
      @data = data
      @collection = options[:collection]
      extend Taggable
    end

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

    def_delegator :@data,:each

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
