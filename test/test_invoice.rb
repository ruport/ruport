require 'rubygems' rescue LoadError nil
require "test/unit"

class SampleInvoiceReport < Ruport::Report
  extend Invoice
end

class TestInvoice < Test::Unit::TestCase
  
  def test_basic
    inv = SampleInvoiceReport.build_invoice do |i|
      i.company_info = "Foo Inc.\n42 Bar Street\nBaz, CT\n"
      i.customer_info = "Gregory Brown\ngregory.t.brown@gmail.com"
      i.data = [[1,2],[3,4]].to_table(%w[a b])
    end
    assert_nothing_raised { inv.render }
    assert_nothing_raised {
      SampleInvoiceReport.render_invoice do |i|
        i.company_info = "Foo Inc.\n42 Bar Street\nBaz, CT\n"
        i.customer_info = "Gregory Brown\ngregory.t.brown@gmail.com"
        i.data = [[1,2],[3,4]].to_table(%w[a b])
      end
    }
  end
          
end
