#FIXME: COPYRIGHT NOTICE

require "ostruct"
module Ruport
  class Format
    class OpenNode < OpenStruct
      include Enumerable
      def initialize(my_name, parent_name, children_name, name, options={})
        @my_children_name = children_name
        @my_parent_name   = parent_name
        @my_name          = my_name
        super(options)
        self.name = name
        send(@my_children_name) || 
        send("#{@my_children_name}=".to_sym,{})
      end
      
     def each(&p)
        send(@my_children_name).values.each(&p)
      end
      
      def add_child(klass,name,options={})
        options[@my_name] = self
        self << klass.new(name, options)
      end
       
      def <<(child)
        child.send("#{@my_name}=".to_sym, self)
        self.send(@my_children_name)[child.name] = child.dup
      end  
      
      def [](child_name)
        self.send(@my_children_name)[child_name]
      end

    end
  end
end
