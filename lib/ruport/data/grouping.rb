module Ruport::Data

  # === Overview
  #
  # This class implements a group data structure for Ruport. Group is
  # simply a subclass of Table that adds a :name attribute.
  # 
  class Group < Table
    attr_reader :name
    attr_reader :subgroups

    # Creates a new group based on the supplied options.
    #
    # Valid options:
    # <b><tt>:name</tt></b>::         The name of the Group
    #
    # All of the options available to Table are also available.
    #
    # Example:
    #
    #   group = Group.new :name => 'My Group',
    #                     :data => [[1,2,3], [3,4,5]], 
    #                     :column_names => %w[a b c]
    #
    def initialize(options={})
      @name = options[:name]
      @subgroups = []
      super
    end

    def as(format,options={})
      Ruport::Renderer::Group.render(format,{:data => self }.merge(options))
    end

    # Create a copy of the Group: records will be copied as well.
    #
    # Example:
    #
    #   one = Group.new :name => 'test',
    #                   :data => [[1,2], [3,4]],
    #                   :column_names => %w[a b]
    #   two = one.dup
    #
    def dup
      obj = super
      obj.name = name
      return obj
    end

    def eql?(other)
      name.eql?(other.name) && super
    end

    alias_method :==, :eql?

    def create_subgroups(group_column)
      if @subgroups.empty?
        @subgroups = grouped_data(group_column)
      else
        @subgroups.each {|group| group.create_subgroups(group_column) }
      end
    end

    protected

    def name=(value) #:nodoc:
      @name = value
    end

  end

  class Grouping  
    
    require "forwardable"
    extend Forwardable
    include Enumerable
    
    attr_reader :data 
    
    def_delegator :@data, :each
    
    def initialize(data,options={})
      cols = Array(options[:by])
      @data = data.send(:grouped_data, cols.shift).inject({}) do |s,r|
        s.merge(r.name => r)
      end
      cols.each do |col|
        @data.each do |name,group|
          group.create_subgroups(col)
        end
      end
    end  
    
    def [](name)
      @data[name] or 
        raise(IndexError,"Group Not Found")
    end 
    
    def <<(group)        
      if data.has_key? group.name
        raise(ArgumentError, "Group '#{group.name}' exists!") 
      end
      @data.merge!({ group.name => group })
    end
    
    alias_method :append, :<<
    
  end
  
end     

module Kernel 
  def Grouping(*args)
    Ruport::Data::Grouping.new(*args)
  end       
  
  def Group(name,opts={})
    Ruport::Data::Group.new(opts.merge(:name => name))  
  end
end
  

