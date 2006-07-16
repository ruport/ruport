module Ruport::Data
  class Table < Ruport::DataSet
    def <<(other)
      row = []
      if other.kind_of? Hash
        column_names.each_with_index { |k,i| row[i] = other[k] }
      else
        row = other
      end
      @data << Record.new(row,:attributes => column_names)
    end
    def empty_clone
      self.class.new([],:attributes => column_names)
    end

  end


end

