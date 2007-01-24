require "rubygems"
require "ruport"
require "invoice"

class SampleReport < Ruport::Report
  include Invoice

  def generate
    render_invoice do |i|
      i.data = [[1,2,3],[4,5,6]].to_table(%w[a b c])

      i.options do |o|
        o.company_info  = "Stone Code Productions\n43 Neagle Street"
        o.customer_info = "Gregory Brown\n200 Foo Ave."
        o.comments      = "J. Random Comment"
        o.order_info    = "Some info\nabout your order"
        o.title         = "Invoice for 12.15.2006 - 12.31.2006"
      end

      i.layout do |lay|
        lay.body_width = 480
        lay.comments_font_size = 12
        lay.title_font_size = 10
      end
    end
  end
end

SampleReport.run { |r| r.write "out.pdf" }
