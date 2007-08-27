# Ruport : Extensible Reporting System                                
#
# data/feeder.rb provides a data transformation and filtering proxy for ruport
#
# Copyright August 2007, Gregory Brown / Michael Milner.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.


# This class provides a simple way to apply transformations and filters that
# get run while you are aggregating data.  This is used primarily to build
# constrained wrappers to Ruport::Data::Table, but can be used with abstract
# data structures as well.
#
# Table Example:
#
#   t = Table(%w[a b c]) do |feeder|
#      feeder.filter { |r| r.a < 5 }
#      feeder.transform { |r| r.b = "B: #{r.b}"}    
#      feeder << [1,2,3]
#      feeder << [7,1,2]
#      feeder << { "a" => 3, "b" => 6, "c" => 7 }
#   end               
#   t.length #=> 2
#   t.column("b") #=> ["B: 2","B: 6"] 
#   
# Filters and transforms are added in a sequential order to a single list of
# constraints.  You could add some constraints and then append some data, then
# add additional constraints, or even build up dynamic constraints if you'd
# like.
#      
# Wrapping an arbitrary data object:
#
# In order to make Data::Feeder work with an object other than Data::Table, it
# must implement two things:
#
#  * A method called feed_element that accepts a single argument.  
#    When Feeder#<< is called, the object to be appended is converted by this
#    method, and then yielded to the filters / transforms.
#
#  * A meaningful #<< method.  Feeder#<< simply delegates this to the wrapped
#    object once the filters and transforms have been applied, so be sure that
#    the object returned by feed_element is one that can be used by your #<<
#    method.
#
# Here is a sample implementation of wrapping a feeder around an Array.
#
#   class Array
#     def feed_element(element)
#       element
#     end  
#   end   
#
#   int_array = []
#   feeder = Ruport::Data::Feeder.new(int_array)
#   feeder.filter { |r| r.kind_of?(Integer) } 
#
#   feeder << 1 << "5" << 4.7 << "kitten" << 4 
#   int_array #=> [1, 4]
#
class Ruport::Data::Feeder
  
  # Creates a new Data::Feeder, wrapping the data object provided. 
  def initialize(data)   
    @data = data   
    @constraints = []
  end                  
  
  # Accesses the underlying data object directly
  attr_reader :data
  
  # Constrained append operation.
  #  
  # Before filters and transforms are run, the element to be appended is first
  # converted by data.feed_element(some_element)
  #
  # Filters and transforms are then run sequentially, and if the constraints
  # are met, it is appended using data << some_element.
  #
  def <<(element)  
    feed_element = data.feed_element(element)
     
    @constraints.each do |type,block|
      if type == :filter
        return self unless block[feed_element]
      else
        block[feed_element]
      end
    end
    
    data << feed_element
    return self
  end
     
  # Creates a filter which must be satisfied for an object to be appended via
  # the feeder.
  #
  #   feeder.filter { |r| r.length < 4 } 
  #
  def filter(&block)
    @constraints << [:filter,block]
  end 
  
  # Creates a transformation which may change the object as it is appended.
  #
  #   feeder.transform { |r| r.a += 10 }
  def transform(&block)
    @constraints << [:transform,block]
  end
  
end