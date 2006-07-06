require "ruport"
require "fileutils"
class MyReport < Ruport::Report
  prepare do
    log_file "f.log"
    log "preparing report", :status => :info
    source :default, 
      :dsn => "dbi:mysql:vagrant_bazaar_development", 
      :user => "root"
    mailer :default,
     :host => "mail.adelphia.net", 
     :address => "gregory.t.brown@gmail.com"
  end
  
  generate do
    log "generated csv from query", :status => :info
    query "select * from users", :as => :csv 
  end

  cleanup do
    log "removing foo.csv", :status => :info
    FileUtils.rm("foo.csv") 
  end
end

MyReport.run { |res| 
  res.write "foo.csv";
  res.send_to("greg7224@gmail.com") do |mail|
    mail.subject = "Sample report" 
    mail.attach "foo.csv"
    mail.text = <<-EOS
      this is a sample of sending an emailed report from within Ruport.
    EOS
  end
}
