# --
# data_row.rb : Ruby Reports row abstraction
#
# Author: Gregory T. Brown (gregory.t.brown at gmail dot com)
#
# Copyright (c) 2006, All Rights Reserved.
#
# This is free software.  You may modify and redistribute this freely under
# your choice of the GNU General Public License or the Ruby License. 
#
# See LICENSE and COPYING for details
# ++
module Ruport 
    
  # DataRows are Enumerable lists which can be accessed by field name or 
  # ordinal position.  
  #
  # They feature a tagging system, allowing them to be easily
  # compared or recalled.  
  #
  # DataRows form the elements of DataSets
  #
    class DataRow 
  
      include Enumerable
    
      # Takes field names as well as some optional parameters and
      # constructs a DataRow.  
      #
      # Options: 
      # <tt>:data</tt>:: can be specified in Hash, Array, or DataRow form
      # <tt>:default</tt>:: The default value for empty fields
      # <tt>:tags</tt>:: an initial set of tags for the row
      # 
      #
      # Examples:
      #   >> Ruport::DataRow.new [:a,:b,:c,:d,:e], :data => [1,2,3,4,5]
      #      :tags => %w[cat dog]
      #   => #<Ruport::DataRow:0xb77e4b04 @fields=[:a, :b, :c, :d, :e], 
      #      @data=[1, 2, 3, 4, 5], @tags=["cat", "dog"]>
      #
      #   >> Ruport::DataRow.new([:a,:b,:c,:d,:e], 
      #      :data => { :a => 'moo', :c => 'caw'} ,
      #      :tags => %w[cat dog])
      #   => #<Ruport::DataRow:0xb77c298c @fields=[:a, :b, :c, :d, :e],
      #      @data=["moo", nil, "caw", nil, nil], @tags=["cat", "dog"]>
      #
      #   >> Ruport::DataRow.new [:a,:b,:c,:d,:e], :data => [1,2,3], 
      #      :tags => %w[cat dog], :default => 0
      #   => #<Ruport::DataRow:0xb77bb4d4 @fields=[:a, :b, :c, :d, :e], 
      #       @data=[1, 2, 3, 0, 0], @tags=["cat", "dog"]>
      #
      def initialize(fields=nil, options={})
        
        #checks to ensure data is convertable
        verify options[:data]
        data = options[:data].dup
        
        @fields   = fields ? fields.dup : ( 0...data.length ).to_a
        @tags     = (options[:tags] || {}).dup
        @data     = []
        
        nr_action = case(data)
          when Array
            lambda {|key, index| @data[index] = data.shift || options[:default]}
          when DataRow
            lambda {|key, index| @data = data.to_a}
          else
            lambda {|key, index| @data[index] = data[key] || options[:default]}
        end     
        @fields.each_with_index {|key, index| nr_action.call(key,index)}
      end

      
      attr_accessor :fields, :tags
      alias_method  :column_names, :fields
      alias_method  :attributes, :fields
      # Returns a new DataRow
      def +(other)
        DataRow.new @fields + other.fields, :data => (@data + other.to_a)
      end

      # Lets you access individual fields
      #
      # i.e. row["phone"] or row[4]
      def [](key)
        case(key)
        when Fixnum
          @data[key]
        when Symbol
          @data[@fields.index(key.to_s)] rescue nil
        else
          @data[@fields.index(key)] rescue nil
        end
      end
      
      # Lets you set field values
      #
      # i.e. row["phone"] = '2038291203', row[7] = "allen"
      def []=(key,value)
        case(key)
        when Fixnum
          @data[key] = value
        when Symbol
          @data[@fields.index(key.to_s)] = value
        else
          @data[@fields.index(key)] = value
        end                          
      end

      # Converts the DataRow to a plain old Array
      def to_a
        @data.clone
      end

      def to_h
        a = Hash.new
        @fields.each { |f| a[f] = self[f] }; a
      end

      # Converts the DataRow to a string representation
      # for outputting to screen.
      def to_s
        "[" + @data.join(",") + "]"
      end
      
      # Checks to see row includes the tag given.
      # 
      # Example:
      #
      #   >> row.has_tag? :running_balance
      #   => true
      #
      def has_tag?(tag)
        @tags.include?(tag)
      end
      
      # Iterates through DataRow elements.  Accepts a block.
      def each(&action)
        @data.each(&action)
      end
      
      # Allows you to add a tag to a row.
      #
      # Examples:
      #
      #   row.tag_as(:jay_cross) if row["product"].eql?("im_courier")
      #   row.tag_as(:running_balance) if row.fields.include?("RB")
      #
      def tag_as(something)
        @tags[something] = true
      end

      # Compares two DataRow objects. If values and fields are the same
      # (and in the correct order) returns true.  Otherwise returns false.
      def ==(other)
        self.to_a.eql?(other.to_a) && @fields.eql?(other.fields)
      end
      
      # Synonym for DataRow#==
      def eql?(other)
        self == other
      end

      def clone
        self.class.new @fields, :data => @data, :tags => @tags
      end

      alias_method :dup, :clone 
      
      private  
      
      def verify(data) 
        if data.kind_of? String  or 
           data.kind_of? Integer or not data.respond_to?(:[])
          Ruport.complain "Cannot convert data to DataRow",
          :status => :fatal, :exception => ArgumentError, :level => :log_only
        end
      end
    
      def method_missing(id,*args)
        f = id.to_s.gsub(/=$/,'')
        return super unless fields.include?(f)
        args.empty? ? self[f] : self[f] = args[0]
      end
  end
end
