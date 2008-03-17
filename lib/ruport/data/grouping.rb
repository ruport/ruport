# Ruport : Extensible Reporting System                                
#
# data/grouping.rb provides group and grouping data structures for Ruport.
#     
# Created by Michael Milner / Gregory Brown, 2007     
# Copyright (C) 2007 Michael Milner / Gregory Brown, All Rights Reserved.  
#
# This is free software distributed under the same terms as Ruby 1.8
# See LICENSE and COPYING for details.   
#
module Ruport::Data

  # === Overview
  #
  # This class implements a group data structure for Ruport. Group is
  # simply a subclass of Table that adds a <tt>:name</tt> attribute.
  # 
  class Group < Table
    
    # The name of the group
    attr_reader :name
    
    # A hash of subgroups
    attr_reader :subgroups

    # Creates a new Group based on the supplied options.
    #
    # Valid options:
    # <b><tt>:name</tt></b>::         The name of the Group
    # <b><tt>:data</tt></b>::         An Array of Arrays representing the 
    #                                 records in this Group
    # <b><tt>:column_names</tt></b>:: An Array containing the column names 
    #                                 for this Group.
    #
    # Example:
    #
    #   group = Group.new :name => 'My Group',
    #                     :data => [[1,2,3], [3,4,5]], 
    #                     :column_names => %w[a b c]
    #
    def initialize(options={})
      @name = options.delete(:name)
      @subgroups = {}
      super
    end
          
    include Ruport::Controller::Hooks
    renders_as_group

    def self.inherited(base) #:nodoc:
      base.renders_as_group
    end

    def initialize_copy(from) #:nodoc:
      super
      @name = from.name
      @subgroups = from.subgroups.inject({}) { |h,d|
        h.merge!({ d[0] => d[1].dup }) }
    end

    # Compares this Group to another Group and returns <tt>true</tt> if
    # the <tt>name</tt>, <tt>data</tt>, and <tt>column_names</tt> are equal.
    #
    # Example:
    #
    #   one = Group.new :name => 'test',
    #                   :data => [[1,2], [3,4]], 
    #                   :column_names => %w[a b]
    #
    #   two = Group.new :name => 'test',
    #                   :data => [[1,2], [3,4]], 
    #                   :column_names => %w[a b]
    #
    #   one.eql?(two) #=> true
    #
    def eql?(other)
      name.eql?(other.name) && super
    end

    alias_method :==, :eql?

    protected

    attr_writer :name, :subgroups #:nodoc:
    
    private
    
    # Creates subgroups for the group based on the supplied column name.  Each
    # subgroup is a hash whose keys are the unique values in the column.
    #
    # Example:
    #
    #   main_group = Group.new :name => 'test',
    #                          :data => [[1,2,3,4,5], [3,4,5,6,7]], 
    #                          :column_names => %w[a b c d e]
    #   main_group.create_subgroups("a")
    #
    def create_subgroups(group_column)
      if @subgroups.empty?
        @subgroups = grouped_data(group_column)
      else
        @subgroups.each {|name,group|
          group.send(:create_subgroups, group_column)
        }
      end
    end

    def grouped_data(group_column) #:nodoc:
      data = {}
      group_names = column(group_column).uniq
      columns = column_names.dup
      columns.delete(group_column)
      group_names.each do |name|
        group_data = sub_table(columns) {|r|
          r.send(group_column) == name
        }
        data[name] = Group.new(:name => name, :data => group_data,
                               :column_names => columns,
                               :record_class => record_class)
      end      
      data
    end

  end
  
  
  # === Overview
  #
  # This class implements a grouping data structure for Ruport.  A grouping is
  # a collection of groups. It allows you to group the data in a table by one
  # or more columns that you specify.
  #   
  # The data for a grouping is a hash of groups, keyed on each unique data
  # point from the grouping column.
  #
  class Grouping
    
    include Enumerable
    
    # Creates a new Grouping based on the supplied options.
    #
    # Valid options:
    # <b><tt>:by</tt></b>::  A column name or array of column names that the
    #                        data will be grouped on. 
    # <b><tt>:order</tt></b>:: Determines the iteration and presentation order
    #                          of a Grouping object.  Set to :name to order by 
    #                          Group names.  You can also provide a lambda which
    #                          will be passed Group objects, and use semantics
    #                          similar to Enumerable#group_by    
    #
    # Examples:
    #
    #   table = [[1,2,3],[4,5,6],[1,1,2]].to_table(%w[a b c])
    #   
    #   # unordered 
    #   grouping = Grouping.new(table, :by => "a")
    #               
    #   # ordered by group name
    #   grouping = Grouping.new(table, :by => "a", :order => :name)
    #
    #   # ordered by group size
    #   grouping = Grouping.new(table, :by => "a", 
    #                                  :order => lambda { |g| g.size } )
    def initialize(data={},options={})
      if data.kind_of?(Hash)
        @grouped_by = data[:by]
        @order = data[:order] 
        @data = {}
      else
        @grouped_by = options[:by]    
        @order = options[:order]
        cols = Array(options[:by]).dup
        @data = data.to_group.send(:grouped_data, cols.shift)
        cols.each do |col|
          @data.each do |name,group|
            group.send(:create_subgroups, col)
          end
        end    
      end
    end
    
    # The grouping's data
    attr_accessor :data
    
    # The name of the column used to group the data
    attr_reader :grouped_by
    
    # Allows Hash-like indexing of the grouping data.
    #
    # Examples:
    #
    #   my_grouping["foo"]
    #
    def [](name)
      @data[name] or 
        raise(IndexError,"Group Not Found")
    end                    
    
    # Iterates through the Grouping, yielding each group name and Group object
    #
    def each 
      if @order.respond_to?(:call) 
        @data.sort_by { |n,g| @order[g] }.each { |n,g| yield(n,g) }
      elsif @order == :name
        @data.sort_by { |n,g| n }.each { |name,group| yield(name,group) } 
      else
        @data.each { |name,group| yield(name,group) }
      end
    end                                                                       
    
    
    # Returns a new grouping with the specified sort order.
    # You can sort by Group name or an arbitrary block
    #
    #   by_name = grouping.sort_grouping_by(:name) 
    #   by_size = grouping.sort_grouping_by { |g| g.size }
    def sort_grouping_by(type=nil,&block)
      a = Grouping.new(:by => @grouped_by, :order => type || block)
      each { |n,g| a << g }
      return a
    end
                                                          
    # Applies the specified sort order to an existing Grouping object.
    #
    #   grouping.sort_grouping_by!(:name)
    #   grouping.sort_grouping_by! { |g| g.size }
    def sort_grouping_by!(type=nil,&block)
      @order = type || block
    end  
    
    # Used to add extra data to the Grouping. <tt>group</tt> should be a Group.
    #
    # Example:
    #
    #   table = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    #
    #   grouping = Grouping.new(table, :by => "a")
    #
    #   group = Group.new :name => 7,
    #                     :data => [[8,9]], 
    #                     :column_names => %w[b c]
    #
    #   grouping << group
    #
    def <<(group)        
      if data.has_key? group.name
        raise(ArgumentError, "Group '#{group.name}' exists!") 
      end
      @data.merge!({ group.name => group })
    end

    alias_method :append, :<< 

    # Provides access to the subgroups of a particular group in the Grouping.
    # Supply the name of a group and it returns a Grouping created from the
    # subgroups of the group.
    #
    def subgrouping(name)
      grouping = dup
      grouping.send(:data=, @data[name].subgroups)
      return grouping
    end
    
    alias_method :/, :subgrouping
   
    # Useful for creating basic summaries from Grouping objects.
    # Takes a field to summarize on, and then for each group,
    # runs the specified procs and returns the results as a Table.
    #     
    # The following example would show for each date group,
    # the sum for the attributes or methods <tt>:opened</tt> and
    # <tt>:closed</tt> and order them by the <tt>:order</tt> array.
    #
    # If <tt>:order</tt> is not specified, you cannot depend on predictable
    # column order.
    #
    #   grouping.summary :date,
    #     :opened => lambda { |g| g.sigma(:opened) },
    #     :closed => lambda { |g| g.sigma(:closed) },
    #     :order => [:date,:opened,:closed]
    #
    def summary(field,procs)     
      if procs[:order].kind_of?(Array)
        cols = procs.delete(:order) 
      else 
        cols = procs.keys + [field]   
      end
      expected = Table(cols) { |t|
        each do |name,group|
          t << procs.inject({field => name}) do |s,r|
            s.merge(r[0] => r[1].call(group))
          end 
        end
        t.data.reorder(cols)     
      }   
    end

    # Uses Ruport's built-in text formatter to render this Grouping
    # 
    # Example:
    # 
    #   table = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    #
    #   grouping = Grouping.new(table, :by => "a")
    #
    #   puts grouping.to_s
    #
    def to_s
      as(:text)
    end
    
    # Calculates sums. If a column name or index is given, it will try to
    # convert each element of that column to an integer or float 
    # and add them together.  The sum is calculated across all groups in
    # the grouping.
    #
    # If a block is given, it yields each Record in each Group so that you can
    # do your own calculation.
    #
    # Example:
    #
    #   table = [[1,2,3],[3,4,5],[5,6,7]].to_table(%w[col1 col2 col3])
    #   grouping = Grouping(table, :by => "col1")
    #   grouping.sigma("col2") #=> 12
    #   grouping.sigma(0)      #=> 12
    #   grouping.sigma { |r| r.col2 + r.col3 } #=> 27
    #   grouping.sigma { |r| r.col2 + 1 } #=> 15
    #
    def sigma(column=nil)
      inject(0) do |s, (group_name, group)|
        if column
          s + group.sigma(column)
        else
          s + group.sigma do |r|
            yield(r)
          end
        end
      end
    end

    alias_method :sum, :sigma

    include Ruport::Controller::Hooks
    renders_as_grouping

    def self.inherited(base) #:nodoc:
      base.renders_as_grouping
    end
    
    # Create a copy of the Grouping. Groups will be copied as well.
    #
    # Example:
    #
    #   table = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    #   one = Ruport::Data::Grouping.new(a, :by => "a")
    #
    #   two = one.dup
    #
    def initialize_copy(from)  #:nodoc:
      @grouped_by = from.grouped_by
      @data = from.data.inject({}) { |h,d| h.merge!({ d[0] => d[1].dup }) }
    end

    # Provides a shortcut for the <tt>as()</tt> method by converting a call to
    # <tt>to_format_name</tt> into a call to <tt>as(:format_name)</tt>.
    #
    def method_missing(id,*args)
      return as($1.to_sym,*args) if id.to_s =~ /^to_(.*)/ 
      super
    end
    
  end
  
end     

module Kernel 

  # Shortcut interface for creating Data::Grouping
  #
  # Example:
  #
  #   a = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
  #   b = Grouping(a, :by => "a")   #=> creates a new grouping on column "a"
  #
  def Grouping(*args)
    Ruport::Data::Grouping.new(*args)
  end       
  
  # Shortcut interface for creating Data::Group
  #
  # Example:
  #
  #   g = Group('mygroup', :data => [[1,2,3],[4,5,6]],
  #         :column_names => %w[a b c])   #=> creates a new group named mygroup
  #
  def Group(name,opts={})
    Ruport::Data::Group.new(opts.merge(:name => name))  
  end
end
