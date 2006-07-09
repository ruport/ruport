# data_set.rb : Ruby Reports core datastructure.
#
# Author: Gregory T. Brown (gregory.t.brown at gmail dot com)
# Copyright (c) 2006, All Rights Reserved.
#
# Pseudo keyword argument support, improved <<, and set operations submitted by
# Dudley Flanders
#
# This is free software.  You may modify and redistribute this freely under
# your choice of the GNU General Public License or the Ruby License. 
#
# See LICENSE and COPYING for details
module Ruport
  
  # The DataSet is the core datastructure for Ruport.  It provides methods that
  # allow you to compare and combine query results, data loaded in from CSVs,
  # and user-defined sets of data.  
  #
  # It is tightly integrated with Ruport's formatting and query systems, so if
  # you'd like to take advantage of these models, you will probably find 
  # DataSet useful.
  class DataSet
    #FIXME: Add logging to this class 
    include Enumerable
    extend Forwardable 
    # DataSets must be given a set of fields to be defined.
    #
    # These field names will define the columns for the DataSet and how you
    # access them.
    #
    #    data = Ruport::DataSet.new %w[ id name phone ]
    #
    # Options:
    # * <tt>:data</tt> - An Enumerable with the content for this DataSet
    # * <tt>:default</tt> - The default value for empty cells
    #
    #
    # DataSet supports the following Array methods through delegators
    # length, empty?, delete_at, first, last, pop
    # 
    def initialize(fields=nil, options={})
      @fields = fields.dup if fields
      @default = options[:default] || default
      @data = []
      options[:data].each { |r| self << r } if options[:data]
    end
    
    #an array which contains column names
    attr_accessor :fields
    alias_method  :column_names, :fields
    
    #the default value to fill empty cells with 
    attr_accessor :default
    
    #data holds the elements of the Row
    attr_reader   :data
    
    def_delegators :@data, :length, :[], :empty?, 
                           :delete_at, :first, :last, :pop,
                           :each, :reverse_each, :at, :clear
    
    def delete_if(&block)
      @data.delete_if &block; self
    end
    
    #provides a deep copy of the DataSet. 
    def clone
      self.class.new(@fields, :data => @data)
    end

    alias_method :dup, :clone

    # Creates a new DataSet with the same shape as this one, but empty.
    def empty_clone
      self.class.new(@fields)
    end

    #allows setting of rows
    def []=(index,data)
      @data[index] = DataRow.new @fields, :data => data
    end

    def [](index)
      case(index)
      when Range
        self.class.new @fields, :data => @data[index] 
      else
       @data[index]
      end
    end

    # Appends a row to the DataSet
    # Can be added as an array, an array of DataRows, a DataRow, or a keyed 
    # hash-like object.
    # 
    # Columns left undefined will be filled with DataSet#default values.
    # 
    #    data << [ 1, 2, 3 ]
    #    data << { :some_field_name => 3, :other => 2, :another => 1 }
    #
    # FIXME: Appending a datarow is wonky.
    def << ( stuff, filler=@default )
      if stuff.kind_of?(DataRow)
        @data << stuff.clone
      elsif stuff.kind_of?(Array) && stuff[0].kind_of?(DataRow)
        @data.concat(stuff)
      else
        @data << DataRow.new(@fields, :data => stuff.clone,:default => filler)
      end
	    return self
    end
    alias_method :push, :<<
    
    # checks if one dataset equals another
    # FIXME: expand this doc.
    def eql?(data2)
      return false unless ( @data.length == data2.data.length and
                            @fields.eql?(data2.fields) )
      @data.each_with_index do |row, r_index|
        row.each_with_index do |field, f_index|
          return false unless field.eql?(data2[r_index][f_index])
        end
      end

      return true
    end

    # checks if one dataset equals another
    def ==(data2)
      eql?(data2)
    end

    # Set union - returns a DataSet with the elements that are contained in
    # in either of the two given sets, with no duplicates.
    def |(other)
      clone << other.reject { |x| self.include? x }
    end 
    alias_method :union, :|

    # Set intersection
    def &(other)
      empty_clone << select { |x| other.include? x }
    end
    alias_method :intersection, :&
    
    # Set difference
    def -(other)
      empty_clone << reject { |x| other.include? x }      
    end
    alias_method :difference, :- 

    # Checks if one DataSet has the same set of fields as another
    def shaped_like?(other)
      return true if @fields.eql?(other.fields)
    end

    # Concatenates one DataSet onto another if they have the same shape
    def concat(other)      
      if other.shaped_like?(self)
        @data.concat(other.data) 
        return self
      end
    end
    alias_method :+, :concat

    # Allows loading of CSV files or YAML dumps. Returns a DataSet
    #
    # FasterCSV will be used if it is installed.
    #
    #   my_data = Ruport::DataSet.load("foo.csv")
    #   my_data = Ruport::DataSet.load("foo.yaml")
    #   my_data = Ruport::DataSet.load("foo.yml")
    def self.load ( source, options={}, &block)
      options = {:has_names => true}.merge(options)
      case source
      when /\.(yaml|yml)/
        return YAML.load(File.open(source))
      when /\.csv/ 
        require "fastercsv"
        input = FasterCSV.read(source) if source =~ /\.csv/
        loaded_data = self.new
        
        action = if block_given? 
          lambda { |r| block[loaded_data,r] }
        else 
          lambda { |r| loaded_data << r } 
        end
       
        if options[:has_names]
          loaded_data.fields = input[0] ; input = input[1..-1]
        end

        loaded_data.default = options[:default]
        input.each { |row| action[row] }
        return loaded_data	
      else
        raise "Invalid file type"
      end
    end
   

    # Returns a new DataSet composed of the fields specified.
    def select_columns(*fields)
      fields = get_field_names(fields)
      rows = fields.inject([]) { |s,e| s + [map { |row| row[e] }] }.transpose
      my_data = DataSet.new(fields, :data => rows)
    end
    
    # Prunes the dataset to contain only the fields specified. (DESTRUCTIVE)
    def select_columns!(*fields)
       a = select_columns(*fields)
       @fields = a.fields; @data   = a.data
    end
      
    #Creates a new dataset with additional columns appending to it
    def add_columns(*fields)
      select_columns *(@fields + fields)
    end

    def add_columns!(*fields)
      select_columns! *(@fields + fields)
    end
    
    # Returns a new DataSet with the specified fields removed
    def remove_columns(*fields)
      fields = get_field_names(fields)
      select_columns(*(@fields-fields))
    end

    # removes the specified fields from this DataSet (DESTRUCTIVE!)
    def remove_columns!(*fields)
      d = remove_columns(*fields)
      @data   = d.data
      @fields = d.fields
    end

    # uses Format::Builder to render DataSets in various ready to output
    # formats.  
    #
    #    data.as(:html)                  -> String
    #
    #    data.as(:text) do |builder|
    #      builder.range = 2..4          -> String
    #      builder.header = "My Title"
    #    end
    #
    # To add new formats to this function, simply re-open Format::Builder
    # and add methods like <tt>render_my_format_name</tt>. 
    #
    # This will enable <tt>data.as(:my_format_name)</tt>
    def as(format,&action)
      t = Format.table_object(:data => clone, :plugin => format)
      action.call(t) if block_given?
      t.render
    end
    
    # Will iterate row by row yielding each row
    # The result of the block will be added to a running total
    #
    # Only works with blocks resulting in numeric values.
    def sigma
      inject(0) do |s,r|
        s + (yield(r) || 0)
      end
    end
    
    alias_method :sum, :sigma

    # Converts a DataSet to an array of arrays 
    def to_a
      @data.map {|x| x.to_a }
    end
         
    # Converts a DataSet to CSV
    def to_csv; as(:csv) end

    # Converts a Dataset to html
    def to_html; as(:html) end
    
    # Readable string representation of the DataSet
    def to_s; as(:text) end

    private

    def get_field_names(f)
      f.all? { |e| e.kind_of? Integer } &&
      f.inject([]) { |s,e| s + [@fields[e]] } || f
    end
    
  end
end

class Array
  
  # Will convert Arrays of Enumerable objects to DataSets. 
  # May have dragons.
  def to_ds(fields,options={})
    Ruport::DataSet.new fields, :data => to_a, :default => options[:default]
  end 
end
