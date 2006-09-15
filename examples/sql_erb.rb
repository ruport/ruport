require "ruport"
require "rubygems"

class Foo < Ruport::Report

  SQL = "select * from <%= helper %>"

  prepare do
    source :default, :dsn => "dbi:mysql:foo", :user => "root"
  end

  generate do
    query(SQL)
  end

  def helper; "bar" end

end

Foo.run { |r| puts r.results }
