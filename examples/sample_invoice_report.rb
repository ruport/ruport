require "rubygems" rescue LoadError nil  
require "ruport"

class SampleInvoiceReport < Ruport::Report

  include Invoice

  #optional
  prepare { self.file = "foo.pdf" }
  
  #mandatory
  generate { 
    render_invoice do |i|
      i.company_info  = "Foo Inc.\n42 Rock Street\nNew Haven, CT"
      i.customer_info = "Gregory Brown\ngregory.t.brown@gmail.com"
      i.order_info = "Order ID: 18180\nCustomer ID: 6291\n" +
                     "Order Date: #{Date.today}"
      i.data = [["Rock Collection","$25.00"],
                 ["Endless Sand Supply","$500.00"],
                 ["Fire Filled Pit","$800.00"]].to_table %w[item price]
      i.comments = "Be sure to visit our website at www.iheartruport.com"
      i.title = "Invoice for Gregory"
      #i.active_plugin.paper = "A4"
    end
  }

  #optional
  cleanup  { }

end

SampleInvoiceReport.run { |res| res.write }
