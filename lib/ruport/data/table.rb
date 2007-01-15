# The Ruport Data Collections.
# Authors: Gregory Brown / Dudley Flanders
#
# This is Free Software.  For details, see LICENSE and COPYING
# Copyright 2006 by respective content owners, all rights reserved.

module Ruport::Data            
  
  #
  # === Overview
  #
  # This class implements some base features for Ruport::Data::Table,
  # and may be used to make interaction with Data::Table like classes
  # easier
  module Collection
    include Enumerable
    include Taggable

    # A simple formatting tool which allows you to quickly generate a formatted
    # table from a <tt>Collection</tt> object.
    #
    # Example:
    #   my_collection.as(:csv)  #=> "1,2,3\n4,5,6"
    def as(type)
      Ruport::Renderer::Table.render(type) do |rend|
        rend.data = self
        yield(rend) if block_given?
      end
    end
   
    # Converts a <tt>Collection</tt> object to a <tt>Data::Table</tt>.
    def to_table(options={})
      Table.new({:data => data.map { |r| r.to_a }}.merge(options))
    end

    # Provides a shortcut for the <tt>as()</tt> method by converting a call to
    # <tt>as(:format_name)</tt> into a call to <tt>to_format_name</tt>
    def method_missing(id,*args)
     return as($1.to_sym) if id.to_s =~ /^to_(.*)/ 
     super
    end
    
  end

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
  class Table 
    include Collection
    include Groupable      
    
    require "forwardable"
    extend Forwardable
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
    attr_reader :data
    def_delegators :@data, :each, :length, :size, :empty?, :[]
    
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
     if @column_names.empty? && @data[0] 
       @column_names.replace(new_column_names.dup)     
       new_column_names.each_with_index { |e,i|
         each { |r| r.rename_attribute(i,e) }
       } 
     elsif @data.empty?     
       @column_names.replace(new_column_names.dup) if @data.empty?             
     else
        column_names.zip(new_column_names).each { |x| 
          rename_column x[0], x[1] if x[0] != x[1]
        }
     end    
     
     each { |r| r.instance_variable_get(:@attributes).replace(@column_names) }             
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
        attributes = @column_names.empty? ? nil : @column_names
        @data << Record.new(other, :attributes => attributes)
      when Hash
        raise ArgumentError unless @column_names
        arr = @column_names.map { |k| other[k] }
        @data << Record.new(arr, :attributes => @column_names)
      when Record
        raise ArgumentError unless column_names.eql? other.attributes
        @data << Record.new(other.to_a, :attributes => @column_names)
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
      
      if indices.all? { |i| i.kind_of? Integer }  
        indices.map! { |i| @column_names[i] }  
      end    
      
      @column_names = indices
                 
      @data.each { |r| 
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
    # <b><tt>:fill</tt></b>:: The default value to use for the column in 
    #                         existing rows. Set to nil if not specified.
    # 
    # <b><tt>:position</tt></b>:: Inserts the column at the indicated position
    #                             number.
    #
    # <b><tt>:before</tt></b>:: Inserts the new column before the column 
    #                           indicated. (by name)
    #
    # <b><tt>:after</tt></b>:: Inserts the new column after the column
    #                           indicated. (by name)
    #
    # If a block is provided, it will be used to build up the column.
    #      
    #   
    # Example:
    #
    #   data = Table("a","b") { |t| t << [1,2] << [3,4] }
    #
    #   data.append_column 'new_column', :default => 1
    #
    def add_column(name,options={})  
      if pos = options[:position]
        column_names.insert(pos,name)   
      elsif pos = options[:after]
        column_names.insert(column_names.index(pos)+1,name)   
      elsif pos = options[:before]
        column_names.insert(column_names.index(pos),name)
      else
        column_names << name
      end 

      if block_given?
        each { |r| r[name] = yield(r) || options[:default] }
      else
        each { |r| r[name] = options[:default] }
      end; self
    end
    
    def remove_column(col)        
      col = column_names[col] if col.kind_of? Fixnum           
      column_names.delete(col)
      each { |r| r.send(:delete,col) }
    end 
    
    def rename_column(old_name,new_name)
      self.column_names[column_names.index(old_name)] = new_name
      each { |r| r.rename_attribute(old_name,new_name,false)} 
    end
    
    def swap_column(a,b)    
      if [a,b].all? { |r| r.kind_of? Fixnum }
       col_a,col_b = column_names[a],column_names[b]
       column_names[a] = col_b
       column_names[b] = col_a
      else
        a_ind, b_ind = [column_names.index(a), column_names.index(b)] 
        column_names[b_ind] = a
        column_names[a_ind] = b
      end
    end
    
    def replace_column(old_col,new_col,&block)
      add_column(new_col,:after => old_col,&block)
      remove_column(old_col)
    end         
    
    def sub_table(columns=column_names,range=nil)      
       Table(columns) do |t|
         if range
           data[range].each { |r| t << r.to_h }
         elsif block_given?
           data.each { |r| t << r.to_h if yield(r) }
         else
           data.each { |r| t << r.to_h } 
         end
       end
    end
    
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

    #
    # Returns a sorted table. If col_names is specified, 
    # the block is ignored and the table is sorted by the named columns. All
    # options are used in constructing the new Table (see Array#to_table
    # for details).
    #
    # Example:
    #
    #   table = [[4, 3], [2, 5], [7, 1]].to_table(%w[col1 col2 ])
    #
    #   # returns a new table sorted by col1
    #   table.sort_rows_by {|r| r["col1"]}
    #
    #   # returns a new table sorted by col2
    #   table.sort_rows_by ["col2"]
    #
    #   # returns a new table sorted by col1, then col2
    #   table.sort_rows_by ["col1", "col2"]
    #
    def sort_rows_by(col_names=nil, &block)
      # stabilizer is needed because of 
      # http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/170565
      stabilizer = 0

      data_array =
        if col_names
          sort_by do |r| 
            stabilizer += 1
            [col_names.map {|col| r[col]}, stabilizer] 
          end
        else
          sort_by(&block)
        end

      table = 
        data_array.to_table(@column_names)

      table.tags = self.tags
      return table
    end
                                                                                
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
                             
    # NOTE: does not respect tainted status
    alias_method :clone, :dup

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
    def self.load(csv_file, options={},&block)
        get_table_from_csv(:foreach, csv_file, options,&block)
    end
    
    #
    # Creates a Table from a CSV string using FasterCSV.  See Table.load for
    # additional examples.
    #
    #   table = Table.parse("a,b,c\n1,2,3\n4,5,6\n")
    #
    def self.parse(string, options={},&block) 
      get_table_from_csv(:parse,string,options,&block)
    end

    private
    
    def self.get_table_from_csv(msg,param,options={},&block) #:nodoc:
      options = {:has_names => true,
                 :csv_options => {} }.merge(options)
      require "fastercsv"
      loaded_data = self.new

      first_line = true
      FasterCSV.send(msg,param,options[:csv_options]) do |row|
        if first_line && options[:has_names]
          loaded_data.column_names = row
          first_line = false
        elsif !block
          loaded_data << row
        else
         block[loaded_data,row]
        end
      end ; loaded_data
    end      
  end
end


module Kernel
  
  # Shortcut interface for creating Data::Tables
  #
  # Examples:
  #
  #   t = Table(%w[a b c])   #=> creates a new empty table w. cols a,b,c
  #   t = Table("a","b","c") #=> creates a new empty table w. cols a,b,c
  #
  #   # allows building table inside of block, returns table object
  #   t = Table(%w[a b c]) { |t| t << [1,2,3] } 
  #
  #   # allows loading table from CSV
  #   # accepts all Data::Table.load options, but block form yields table,
  #   # not row!
  #
  #   t = Table("foo.csv")
  #   t = Table("bar.csv", :has_names => false)
  def Table(*args,&block)
    table=
    case(args[0])
    when Array
      [].to_table(args[0])
    when /\.csv/
      Ruport::Data::Table.load(*args)
    else
       [].to_table(args)
    end             
    
    block[table] if block
    return table
  end
end  

class Array
  #
  # Converts an array to a Ruport::Data::Table object, ready to
  # use in your reports.
  #
  # Example:
  #   [[1,2],[3,4]].to_table(%w[a b])
  #
  def to_table(column_names=nil)
    Ruport::Data::Table.new({:data => self, :column_names => column_names})
  end
end