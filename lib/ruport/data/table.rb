module Ruport::Data
  class Table < Collection
    def initialize(options={})
      @column_names = options[:column_names].dup if options[:column_names]
      @data         = []
      options[:data].each { |e| self << e }  if options[:data]
    end

    attr_reader :column_names

    def column_names=(other)
      @column_names = other.dup
    end

    def <<(other)
      case(other)
      when Array
        @data << Record.new(other, :attributes => @column_names)
      when Hash
        raise unless @column_names
        arr = @column_names.map { |k| other[k] }
        @data << Record.new(arr, :attributes => @column_names)
      when Record
        raise ArgumentError unless column_names.eql? other.attributes
        @data << Record.new(other.to_a, :attributes => @column_names)
      end
      self
    end

    def reorder!(*indices)
      @column_names = indices
      @data.each { |r| r.reorder! *indices }; self
    end

    def reorder(*indices)
      dup.reorder! *indices
    end

    def dup
      a = self.class.new(:data => @data, :column_names => @column_names)
    end

    def self.load(csv_file, options = {})
      options = {:has_names => true}.merge(options)
      require "fastercsv"
      loaded_data = self.new

      first_line = true
      FasterCSV.foreach(csv_file) do |row|
        if first_line && options[:has_names]
          loaded_data.column_names = row
          first_line = false
        elsif !block_given?
          loaded_data << row
        else
          yield(loaded_data,row)
        end
      end
      return loaded_data
    end

    def split(options={})
      group = map { |r| r[options[:group]] }.uniq 
      data = []
      group.each { |g| 
        data << select { |r| r[options[:group]].eql?(g) } 
      }
      c = column_names - [options[:group]]
      data.map! { |g| 
        Ruport::Data::Table.new(
          :data => g.map { |x| x.reorder(*c) },
          :column_names => c
        )
      }
      Ruport::Data::Record.new data, :attributes => group
    end

  end
end
