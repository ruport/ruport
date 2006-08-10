module Ruport
  class Report
    module Invoice
      def build_invoice
        a = Ruport::Format.invoice_object(:plugin => :pdf)
        yield(a); return a
      end
      def render_invoice(&block)
        build_invoice(&block).render
      end
    end
  end
end
