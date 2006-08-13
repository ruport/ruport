module Ruport
  class Report
    module Invoice
      
      # Returns a Format::Engine::Invoice object
      #
      # If a block is given, it is possible to customize this object before it
      # is returned
      #
      # Example:
      #
      #   inv = build_invoice do |i|
      #     i.company_info  = "Foo Inc.\n42 Front Street\nNew Haven CT"
      #     i.customer_info = "Joe User\njoe@test.com"
      #     i.data = [["Aspirin","$2.00"]].to_table(%w[item cost])
      #   end
      def build_invoice
        a = Ruport::Format.invoice_object(:plugin => :pdf)
        yield(a); return a
      end

      # Takes a block and calls build_invoice then calls render on the resulting
      # Format::Engine::Invoice object
      def render_invoice(&block)
        build_invoice(&block).render
      end
    end
  end
end
