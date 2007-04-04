module Ruport
  class Renderer::Options < OpenStruct #:nodoc:
    def to_hash
      @table
    end   
    def [](key)
      send(key)
    end
    def []=(key,value)
      send("#{key}=",value)
    end
  end
end
