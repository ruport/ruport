require "ruport"

TEMPLATE = <<-EOS

My HTML Table:
  <%= query "select * from bar", :as => :html %>

EOS

class MyReport < Ruport::Report
  prepare  { source :default, :dsn => "dbi:mysql:foo", :user => "root" }
  generate { eval_template TEMPLATE }
end

MyReport.run
