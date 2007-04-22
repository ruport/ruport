require "ruport"

Ruport::Query.add_source :default, :user => "root",
                                   :dsn  => "dbi:mysql:mydb"
