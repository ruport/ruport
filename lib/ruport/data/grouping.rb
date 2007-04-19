module Ruport::Data

  # === Overview
  #
  # This class implements a group data structure for Ruport. Group is
  # simply a subclass of Table that adds a :name attribute.
  # 
  class Group < Table
    
    attr_reader :name, :subgroups

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
          
    include Ruport::Renderer::Hooks
    renders_with Ruport::Renderer::Group

    # Create a copy of the Group: records will be copied as well.
    #
    # Example:
    #
    #   one = Group.new :name => 'test',
    #                   :data => [[1,2], [3,4]],
    #                   :column_names => %w[a b]
    #   two = one.dup
    #
    def initialize_copy(from)
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
        @subgroups.each {|name,group| group.create_subgroups(group_column) }
      end
    end

    protected

    attr_writer :name, :subgroups
    
    private
    
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
    #
    # Example:
    #
    #   table = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    #
    #   grouping = Grouping.new(table, :by => "a")
    #
    def initialize(data,options={})
      @grouped_by = options[:by] 
      cols = Array(options[:by]).dup
      @data = data.to_group.send(:grouped_data, cols.shift)
      cols.each do |col|
        @data.each do |name,group|
          group.create_subgroups(col)
        end
      end
    end
    
    attr_accessor :data 
    attr_reader :grouped_by
    
    require "forwardable"
    extend Forwardable
    def_delegator :@data, :each
    
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
    
    # Used to add extra data to the Grouping. <tt>other</tt> should be a Group.
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

    def /(name)
      grouping = dup
      grouping.send(:data=, @data[name].subgroups)
      return grouping
    end 
   
    # Useful for creating basic summaries from Grouping objects.
    # Takes a field to summarize on, and then for each group,
    # runs the specified procs and returns the results as a Table
    #     
    # The following example would show for each date group,
    # the sum for the attributes or methods :opened and :closed
    # and order them by the :order array.
    #
    # If :order is not specified, you cannot depend on predictable column order
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
       t.reorder(cols)     
      }   
    end
    
    alias_method :append, :<<

    def to_s
      as(:text)
    end  
    
    include Ruport::Renderer::Hooks
    renders_with Ruport::Renderer::Grouping
    
    # Create a copy of the Grouping: groups will be copied as well.
    #
    # Example:
    #
    #   table = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    #   one = Ruport::Data::Grouping.new(a, :by => "a")
    #
    #   two = one.dup
    #
    def initialize_copy(from)
      @grouped_by = from.grouped_by
      @data = from.data.inject({}) { |h,d| h.merge!({ d[0] => d[1].dup }) }
    end

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
  #   a = [[1,2,3],[4,5,6]].to_table(%w[a b c])
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
