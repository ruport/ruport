module Ruport
  module MetaTools
    def singleton; (class << self; self; end); end

    def attribute(sym,value = nil)
      singleton.send(:attr_accessor, sym )
      self.send("#{sym}=",value)
    end

    def attributes(syms)
      syms.each { |s| attribute s }
    end

    def action(name,&block)
      singleton.send(:define_method, name, &block)
    end
  end
end

