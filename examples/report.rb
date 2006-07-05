require "ruport"
require "fileutils"
class MyReport < Ruport::Report
  prepare do
    log_file "f.log"
    log "preparing report", :status => :info
    source :default, 
      :dsn => "dbi:mysql:vagrant_bazaar_development", 
      :user => "root"
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
  puts File.read("foo.csv")
}
