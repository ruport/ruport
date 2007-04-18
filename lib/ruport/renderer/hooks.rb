module Ruport::Renderer::Hooks
  module ClassMethods
    def renders_with(klass)
      @renderer = klass
    end                       
    
    def renderer
      @renderer
    end
  end
  
  def self.included(base)
    base.extend(ClassMethods)
  end      
  
  def as(*args)
    unless self.class.renderer.formats.include?(args[0])
      raise ArgumentError
    end
    self.class.renderer.render(*args) do |rend|
      rend.data = self
      yield(rend) if block_given?  
    end
  end  
  
end