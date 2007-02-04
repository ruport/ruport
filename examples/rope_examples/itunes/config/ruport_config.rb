require "ruport"

# For details, see Ruport::Config documentation
Ruport.configure { |c|
  c.source :default, :user     => "root", 
                     :dsn      =>  "dbi:mysql:mydb"
  c.log_file "log/ruport.log"
}
