# The Ruport Data Collections.
# Authors: Gregory Brown / Dudley Flanders
#
# This is Free Software.  For details, see LICENSE and COPYING
# Copyright 2006 by respective content owners, all rights reserved.

class Array
  # Converts an array to a Ruport::Data::Table object, ready to
  # generate reports with.
  #
  #   [[1,2],[3,4]].to_table(%w[a b])
  def to_table(options={})
    options = { :column_names => options } if options.kind_of? Array 
    Ruport::Data::Table.new({:data => self}.merge(options))
  end
end

module Ruport::Data
  
  # This class is one of the core class for building and working with data in
  # Ruport. The idea is to get your data into a standard form, regardless of 
  # it's source (files, a database, manual arrays, active record, CSV).
  # 
  # Table is intended to be used as the data store for structured, tabular
  # data - Ruport::Data::Set is an alternate intermediary data store intended
  # for less structured data.
  #
  # Once your data is into a Ruport::Data::Table object, it can be manipulated
  # to suit your needs, then used to build a report.
  #
  # Included in this class are methods to create Table's manually and from CSV.
  # For building a table using ActiveRecord, have a look at Ruport::Reportable 
  class Table < Collection

    # Creates a new table based on the supplied options
    # Valid options are :data and :column_names
    #
    #   table = Table.new({:data => [1,2,3], [3,4,5], 
    #                      :column_names => %w[a b c]})
    def initialize(options={})
      @column_names = options[:column_names].dup if options[:column_names]
      @data         = []
      options[:data].each { |e| self << e }  if options[:data]
    end

    attr_reader :column_names

    # Sets the column names for this table.
    # Single parameter should be an array listing the names
    #
    #   tbl = Table.new({:data => [1,2,3], [3,4,5], :column_names => %w[a b c]})
    #   tbl.column_names = %w[e f g]
    def column_names=(other)
      @column_names = other.dup
      map { |r| r.attributes = @column_names }
    end

    # Compares this table to another table and returns true if
    # both the data and column names are equal
    #
    #   one = Table.new({:data => [1,2], [3,4], :column_names => %w[a b]})
    #   two = Table.new({:data => [1,2], [3,4], :column_names => %w[a b]})
    #   one.eql?(two) #=> true
    def eql?(other)
      data.eql?(other.data) && column_names.eql?(other.column_names) 
    end
    alias_method :==, :eql?

    # Uses ruports inbuilt text plugin to render this table into a string
    # 
    #   data = Table.new({:data => [1,2], [3,4], :column_names => %w[a b]})
    #   puts data.to_s
    def to_s
      as(:text)
    end

    # Used too add extra data to the table. The single parameter can be an 
    # Array, Hash or Ruport::Data::Record.
    #
    #   data = Table.new({:data => [1,2], [3,4], :column_names => %w[a b]})
    #   data << [8,9]
    #   data << { :a => 4, :b => 5}
    #   data << Ruport::Data::Record.new [5,6], :attributes => %w[a b]
    def <<(other)
      case other
      when Array
        @data << Record.new(other, :attributes => @column_names)
      when Hash
        raise unless @column_names
        arr = @column_names.map { |k| other[k] }
        @data << Record.new(arr, :attributes => @column_names)
      when Record
        raise ArgumentError unless column_names.eql? other.attributes
        @data << Record.new(other.data, :attributes => @column_names)
        @data.last.tags = other.tags.dup
      end
      self
    end
  
    # Reorders the columns that exist in the table. Operates directly 
    # on this table.
    #
    #   data = Table.new({:data => [1,2], [3,4], :column_names => %w[a b]})
    #   data.reorder!([1,0])  
    def reorder!(*indices)
      indices = indices[0] if indices[0].kind_of? Array
      @column_names = if indices.all? { |i| i.kind_of? Integer }
        indices.map { |i| @column_names[i] }
      else
        indices 
      end
      @data.each { |r| r.reorder! *indices }; self
    end

    # returns a copy of the table with it's columns in the requested order
    #
    #   one = Table.new({:data => [1,2], [3,4], :column_names => %w[a b]})
    #   two = one.reorder!([1,0])  
    def reorder(*indices)
      dup.reorder! *indices
    end

    # adds an extra column to the table. Accepts an options Hash as its
    # only parameter which should contain 2 keys - :name and :fill
    # :name species the new columns name, and :fill the default value to 
    # use for the column in existing rows.
    #   
    #   data = Table.new({:data => [1,2], [3,4], :column_names => %w[a b]})
    #   data.append_coulmn({:name => 'new_column', :fill => 1)
    def append_column(options={})
      self.column_names += [options[:name]]  if options[:name]
      if block_given?
        each { |r| r.data << yield(r) || options[:fill] }
      else
        each { |r| r.data << options[:fill] }
      end
    end

    # Create a shallow copy of the table: the same data elements are referenced
    # by both the old and new table
    #
    #   one = Table.new({:data => [1,2], [3,4], :column_names => %w[a b]})
    #   two = one.dup
    def dup
      a = self.class.new(:data => @data, :column_names => @column_names)
      a.tags = tags.dup
      return a
    end

    # loads a CSV file directly into a table using the fasterCSV library.
    #   
    #   data = Table.load('mydata.csv')
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
      end ; loaded_data
    end

    # Used for advanced grouping functionality. More info to come
    def split(options={})
      if options[:group].kind_of? Array
        group = map { |r| options[:group].map { |e| r[e] } }.uniq
         data = group.inject([]) { |s,g|
           s + [select { |r| options[:group].map { |e| r[e] }.eql?(g) }]
         }
         c = column_names - options[:group]
      else
        group = map { |r| r[options[:group]] }.uniq 
        data = group.inject([]) { |s,g| 
          s + [select { |r| r[options[:group]].eql?(g) }] 
        }
        c = column_names - [options[:group]]

      end 
      data.map! { |g| 
        Ruport::Data::Table.new(
          :data => g.map { |x| x.reorder(*c) },
          :column_names => c
        )
      }
      if options[:group].kind_of? Array
        Ruport::Data::Record.new(data, 
          :attributes => group.map { |e| e.join("_") } )
      else
        Ruport::Data::Record.new data, :attributes => group
      end
    end
    
  end
end
