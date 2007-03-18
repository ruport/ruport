module Ruport
  class Renderer::Options < OpenStruct
    def to_hash
      @table
    end
  end
end
