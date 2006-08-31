module Ruport
  class Format::Engine
    class Document < Format::Engine
      renderer do
        super
        apply_erb if erb_enabled
        apply_red_cloth if red_cloth_enabled
        active_plugin.render_document
      end

      class << self
        
        attr_accessor :red_cloth_enabled
        attr_accessor :erb_enabled
        
        def apply_red_cloth
          require "redcloth"
          active_plugin.data = RedCloth.new(active_plugin.data).to_html
        end
            
      end
      
      alias_engine Document, :document_engine
      Format.build_interface_for Document, :document 
    end
  end
end

