# FIXME: Copyright notice
# HERE THERE BE DRAGONS!
require "ostruct"
module Ruport
  class Format
    class Document < OpenStruct
      include Enumerable       
      
      def initialize(name,options={})
          super(options)
          self.name = name
          self.pages ||= []
      end
      
      def each
        self.pages.each { |p| yield(p) }
      end
      
      def add_page(name,options={})
          options[:document] = self
          self.pages << Format::Page.new(name,options)
      end
      
      def <<(page)
        page.document = self
        self.pages << page.dup
      end
      
      def [](page_name)
        return self.pages[page_name] if page_name.kind_of? Integer
        self.pages.find { |p| p.name.eql?(page_name) }
      end
      
      def clone
        cloned = self.clone
        cloned.pages = self.pages.clone
        return cloned
      end
    end

    class Page < Format::OpenNode
      
      def initialize(name,options={})        
        super(:page,:document,:sections,name,options)
      end
      
      def add_section(name,options={})
        add_child(Format::Section,name,options)
      end
      
    end
    
    class Section < Format::OpenNode
      
      def initialize(name, options={})
        super(:section,:page,:elements,name,options)
      end
      
      def add_element(name,options={})
        add_child(Format::Element,name,options)
      end
      
    end

    class Element < OpenStruct
      
      def initialize(name,options={})
        super(options)
        self.name = name
      end
      
      def to_s
        self.content
      end
      
    end
  end
end
