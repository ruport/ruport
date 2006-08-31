module Ruport
  class Format::Engine
    class Format::Engine::Invoice < Ruport::Format::Engine

      # order meta data
      attributes [ :customer_info, :company_info, 
                   :comments, :order_info, :title]
     
      renderer do
        super
        build_headers
        build_body
        build_footer
        active_plugin.render_invoice
      end
    
      alias_engine Invoice, :invoice_engine
      Ruport::Format.build_interface_for Invoice, :invoice
    
    end
  end
end

