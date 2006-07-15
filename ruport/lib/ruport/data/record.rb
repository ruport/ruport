module Ruport::Data
  class Record
    require "forwardable"
    extend Forwardable
    include Enumerable

    def initialize(data,options={})
      @data = data
      @collection = options[:collection]
    end

    def [](index)
      if index.kind_of? Integer
        @data[index]
      else
        @data[@collection.column_names.index(index)]
      end
    end

    def_delegator :@data,:each

    def method_missing(id)
      if @collection.column_names.include?(id)
        self[id]
      elsif @collection.column_names.include?(id.to_s) 
        self[id.to_s]
      else
        super
      end
    end

  end
end
