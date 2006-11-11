# Gets raised if you try to add the same action to an object more than once. 
class ActionAlreadyDefinedError < RuntimeError; end

module Ruport

  # 
  # === Overview
  #
  # This module provides a few tools for doing some manipulations of the
  # singleton class of an object.  These are used in the implementation of 
  # Ruport's formatting system, and might be useful for other things.
  #
  module MetaTools
    #
    # Allows you to define an attribute accessor on the singleton class.
    #
    # Example:
    # 
    #  class A
    #     extend Ruport::MetaTools
    #     attribute :foo
    #  end
    #
    #  A.foo      #=> nil
    #  A.foo = 7  #=> 7 
    #
    def attribute(sym,value = nil)
      singleton_class.send(:attr_accessor, sym )
      self.send("#{sym}=",value)
    end

    #
    # Same as <tt>attribute</tt>, but takes an Array of attributes.
    #
    # Example:
    # 
    #   attributes [:foo,:bar,:baz]
    #
    def attributes(syms)
      syms.each { |s| attribute s }
    end
    
    #
    # Allows you to define a method on the singleton class.
    #
    # Example:
    #
    #   class A
    #     extend Ruport::MetaTools
    #     action(:bar) { |x| x + 1 }
    #   end
    #
    #   A.bar(3)  #=> 4
    #
    def action(name,&block)
      raise ActionAlreadyDefinedError if respond_to? name
      singleton_class.send(:define_method, name, &block)
    end
    
  end
end

class Module
  # Provides the singleton_class object.
  def singleton_class; (class << self; self; end); end
end
