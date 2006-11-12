# The Ruport Data Collections.
# Authors: Gregory Brown / Dudley Flanders
#
# This is Free Software.  For details, see LICENSE and COPYING
# Copyright 2006 by respective content owners, all rights reserved.

class Array

  #
  # Converts an array to a Ruport::Data::Table object, ready to
  # use in your reports.
  #
  # Example:
  #   [[1,2],[3,4]].to_table(%w[a b])
  #
  def to_table(options={})
    options = { :column_names => options } if options.kind_of? Array 
    Ruport::Data::Table.new({:data => self}.merge(options))
  end
end

module Ruport::Data

  # 
  # === Overview
  #
  # This class is one of the core classes for building and working with data 
  # in Ruport. The idea is to get your data into a standard form, regardless 
  # of its source (a database, manual arrays, ActiveRecord, CSVs, etc.).
  # 
  # Table is intended to be used as the data store for structured, tabular
  # data - Ruport::Data::Set is an alternate data store intended for less 
	# structured data.
  #
  # Once your data is in a Ruport::Data::Table object, it can be manipulated
  # to suit your needs, then used to build a report.
  #
  class Table < Collection
    include Groupable
    
    #
    # Creates a new table based on the supplied options.
    # Valid options: 
    # <b><tt>:data</tt></b>::         An Array of Arrays representing the 
    #                                 records in this Table
    # <b><tt>:column_names</tt></b>:: An Array containing the column names 
    #                                 for this Table.
    # Example:
    #
    #   table = Table.new :data => [[1,2,3], [3,4,5]], 
    #                     :column_names => %w[a b c]
    #
    def initialize(options={})
      @column_names = options[:column_names] ? options[:column_names].dup : []
      @data         = []
      if options[:data]
        if options[:data].all? { |r| r.kind_of? Record }
          record_tags = options[:data].map { |r| r.tags }
          options[:data] = options[:data].map { |r| r.to_a } 
        end 
        options[:data].each { |e| self << e }  
        each { |r| r.tags = record_tags.shift } if record_tags
      end
    end

    # This Table's column names.
    attr_reader :column_names
    def_delegator :@data, :[]
    
    #
    # Sets the column names for this table. <tt>new_column_names</tt> should 
    # be an array listing the names of the columns.
    #
    # Example:
    #
    #   table = Table.new :data => [1,2,3], [3,4,5], 
    #                     :column_names => %w[a b c]
    #
    #   table.column_names = %w[e f g]
    #
    def column_names=(new_column_names)
      @column_names.replace(other.dup)
    end

    #
    # Compares this Table to another Table and returns <tt>true</tt> if
    # both the <tt>data</tt> and <tt>column_names</tt> are equal.
    #
    # Example:
    #
    #   one = Table.new :data => [1,2], [3,4], 
    #                   :column_names => %w[a b]
    #
    #   two = Table.new :data => [1,2], [3,4], 
    #                   :column_names => %w[a b]
    #
    #   one.eql?(two) #=> true
    #
    def eql?(other)
      data.eql?(other.data) && column_names.eql?(other.column_names) 
    end

    alias_method :==, :eql?

    #
    # Uses Ruport's built-in text plugin to render this Table into a String
    # 
    # Example:
    # 
    #   data = Table.new :data => [1,2], [3,4], 
    #                    :column_names => %w[a b]
    #   puts data.to_s
    # 
    def to_s
      as(:text)
    end

    #
    # Used to add extra data to the Table. <tt>other</tt> can be an Array, 
    # Hash or Record.
    #
    # Example:
    #
    #   data = Table.new :data => [1,2], [3,4], 
    #                    :column_names => %w[a b]
    #   data << [8,9]
    #   data << { :a => 4, :b => 5}
    #   data << Record.new [5,6], :attributes => %w[a b]
    #
    def <<(other)
      case other
      when Array
        @data << Record.new(other, :attributes => @column_names)
      when Hash
        raise ArgumentError unless @column_names
        arr = @column_names.map { |k| other[k] }
        @data << Record.new(arr, :attributes => @column_names)
      when Record
        raise ArgumentError unless column_names.eql? other.attributes
        @data << Record.new(other.data, :attributes => @column_names)
        @data.last.tags = other.tags.dup
      else
        raise ArgumentError
      end
      self
    end
  
    #
    # Used to combine two Tables. Throws an ArgumentError if the Tables don't
    # have identical columns.
    #
    # Example:
    #
    #   inky = Table.new :data => [[1,2], [3,4]], 
    #                    :column_names => %w[a b]
    #
    #   blinky = Table.new :data => [[5,6]], 
    #                      :column_names => %w[a b]
    #
    #   sue = inky + blinky
    #   sue.data #=> [[1,2],[3,4],[5,6]]
    #
    def +(other)
      raise ArgumentError unless other.column_names == @column_names
      Table.new(:column_names => @column_names, :data => @data + other.data)
    end
  
    #
    # Reorders the columns that exist in the Table. Modifies this Table 
    # in-place.
    #
    # Example:
    #
    #   data = Table.new :data => [1,2], [3,4], 
    #                    :column_names => %w[a b]
    #
    #   data.reorder!([1,0])  
    #
    def reorder!(*indices)
      indices = indices[0] if indices[0].kind_of? Array

      if @column_names && !@column_names.empty?
        x = if indices.all? { |i| i.kind_of? Integer }
          indices.map { |i| @column_names[i] }
        else
          indices 
        end
        @column_names = x
      end
      @data.each { |r| 
        r.reorder_data!(*indices)
        r.attributes = @column_names
      }; self
    end

    #
    # Returns a copy of the Table with its columns in the requested order.
    #
    # Example:
    # 
    #   one = Table.new :data => [1,2], [3,4], 
    #                   :column_names => %w[a b]
    #
    #   two = one.reorder!([1,0])  
    #
    def reorder(*indices)
      dup.reorder!(*indices)
    end

    #
    # Adds an extra column to the Table. Available Options:
    #
    # <b><tt>:name</tt></b>:: The new column's name (required)
    # <b><tt>:fill</tt></b>:: The default value to use for the column in 
    #                         existing rows. Set to nil if not specified.
    #   
    # Example:
    #
    #   data = Table.new :data => [1,2], [3,4], 
    #                    :column_names => %w[a b]
    #
    #   data.append_column :name => 'new_column', :fill => 1
    #
    def append_column(options={})
      self.column_names += [options[:name]]  if options[:name]
      if block_given?
        each { |r| r.data << yield(r) || options[:fill] }
      else
        each { |r| r.data << options[:fill] }
      end; self
    end

    # 
    # Removes a column from the Table. Any values in the specified column are
    # lost.
    #
    # Example:
    #
    #   data = Table.new :data => [[1,2], [3,4]], :column_names => %w[a b]
    #   data.append_column :name => 'new_column', :fill => 1
    #   data.remove_column :name => 'new_column'
    #   data == Table.new :data => [[1,2], [3,4]], 
    #                     :column_names => %w[a b] #=> true
    #   data = [[1,2],[3,4]].to_table
    #   data.remove_column(1)
    #   data.eql? [[1],[3]].to_table %w[a] #=> true
    #
    def remove_column(options={})    
      if options.kind_of? Integer
        return reorder!((0...data[0].length).to_a - [options])
      elsif options.kind_of? Hash
       name = options[:name]
      else
       name = options
      end
      
      raise ArgumentError unless column_names.include? name
      reorder! column_names - [name]
    end

    #
    # Create a copy of the Table: records will be copied as well.
    #
    # Example:
    #
    #   one = Table.new :data => [1,2], [3,4], 
    #                   :column_names => %w[a b]
    #   two = one.dup
    #
    def dup
      a = self.class.new(:data => @data, :column_names => @column_names)
      a.tags = tags.dup
      return a
    end

    #
    # Loads a CSV file directly into a Table using the FasterCSV library.
    #
    # Example:
    #   
    #   # treat first row as column_names
    #   table = Table.load('mydata.csv')
    #
    #   # do not assume the data has column_names
    #   table = Table.load('mydata.csv',:has_names => false)
    #
    #   # pass in FasterCSV options, such as column separators
    #   table = Table.load('mydata.csv',:csv_opts => { :col_sep => "\t" })
    #
    def self.load(csv_file, options={})
        get_table_from_csv(:foreach, csv_file, options)
    end
    
    #
    # Creates a Table from a CSV string using FasterCSV.  See Table.load for
    # additional examples.
    #
    #   table = Table.parse("a,b,c\n1,2,3\n4,5,6\n")
    #
    def self.parse(string, options={}) 
      get_table_from_csv(:parse,string,options)
    end
    
    def self.get_table_from_csv(msg,param,options={}) #:nodoc:
      options = {:has_names => true,
                 :csv_options => {} }.merge(options)
      require "fastercsv"
      loaded_data = self.new

      first_line = true
      FasterCSV.send(msg,param,options[:csv_options]) do |row|
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

    # 
    # Allows you to split Tables into multiple Tables for grouping.
    #
    # Example:
    #
    #   a = Table.new(:column_name => %w[name a b c])
    #   a << ["greg",1,2,3]
    #   a << ["joe", 2,3,4]
    #   a << ["greg",7,8,9]
    #   a << ["joe", 1,2,3]
    #
    #   b = a.split :group => "name"
    #
    #   b.greg.eql? [[1,2,3],[7,8,9]].to_table(%w[a b c]) #=> true
    #   b["joe"].eql? [[2,3,4],[1,2,3]].to_table(%w[a b c]) #=> true
    #
    # You can also pass an Array to <tt>:group</tt>, and the resulting 
    # attributes in the group will be joined by an underscore. 
    # 
    # Example:
    #
    #   a = Table.new(:column_names => %w[first_name last_name x]
    #   a << %w[greg brown foo]
    #   a << %w[greg gibson bar]
    #   a << %w[greg brown baz]
    #
    #   b = a.split :group => %w[first_name last_name]
    #   a.greg_brown.length     #=> 2
    #   a["greg_gibson"].length #=> 1
    #   a.greg_brown[0].x       #=> "foo"
    #
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
      rec = if options[:group].kind_of? Array
        Ruport::Data::Record.new(data, 
          :attributes => group.map { |e| e.join("_") } )
      else
        Ruport::Data::Record.new data, :attributes => group
      end
      class << rec
        def each_group; attributes.each { |a| yield(a) }; end
      end; rec
    end
    
    # 
    # Calculates sums. If a column name or index is given, it will try to
    # convert each element of that column to an integer or float 
    # and add them together.
    #
    # If a block is given, it yields each Record so that you can do your own 
    # calculation.
    #
    # Example:
    #
    #   table = [[1,2],[3,4],[5,6]].to_table(%w[col1 col2])
    #   table.sigma("col1") #=> 9
    #   table.sigma(0)      #=> 9
    #   table.sigma { |r| r.col1 + r.col2 } #=> 21
    #   table.sigma { |r| r.col2 + 1 } #=> 15
    #
    def sigma(column=nil)
      inject(0) { |s,r| 
        if column
          s + if r[column].kind_of? Numeric
            r[column]
          else
            r[column] =~ /\./ ? r[column].to_f : r[column].to_i
          end
        else
          s + yield(r)    
        end
      }
    end

    alias_method :sum, :sigma
    
  end

end

module Ruport::Data::TableHelper #:nodoc:
  def table(names=[])
    t = [].to_table(names)
    yield(t) if block_given?; t
  end
end
