class ActionAlreadyDefinedError < RuntimeError; end
module Ruport
  # This module provides a few tools for doing some manipulations of the
  # eigenclass on an object.  These are used in the implementation of Ruport's
  # formatting system, and might be helpful for other things.
  #
  module MetaTools
    # allows you to define an attribute accessor on the singleton_class.
    #
    # Example:
    # 
    #  class A
    #     extend Ruport::MetaTools
    #     attribute :foo
    #  end
    #
    #  A.foo #=> nil
    #  A.foo = 7 #=> 7 
    def attribute(sym,value = nil)
      singleton_class.send(:attr_accessor, sym )
      self.send("#{sym}=",value)
    end

    # same as attribute, but takes an array of attributes
    #
    # e.g. attributes [:foo,:bar,:baz]
    def attributes(syms)
      syms.each { |s| attribute s }
    end
    
    # allows you to define a method on the singleton_class
    #
    # Example:
    #
    #   class A
    #     extend Ruport::MetaTools
    #     action(:bar) { |x| x + 1 }
    #   end
    #
    #   A.bar(3) #=> 4
    def action(name,&block)
      raise ActionAlreadyDefinedError if respond_to? name
      singleton_class.send(:define_method, name, &block)
    end
  end
end

class Module
    # provides the singleton_class object
    def singleton_class; (class << self; self; end); end
end
