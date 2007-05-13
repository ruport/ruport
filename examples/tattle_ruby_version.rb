require "rubygems"
require "ruport"
require "active_record"
require "ruport/acts_as_reportable"

# Update with your connection parameters
ActiveRecord::Base.establish_connection(
    :adapter  => 'mysql',
    :host     => 'localhost',
    :username => 'mike',
    :password => 'password',
    :database => 'tattle')

class Report < ActiveRecord::Base
  acts_as_reportable
end

table = Report.report_table(:all,
  :only       => %w[host_os ruby_version user_key],
  :conditions => "user_key is not null and user_key <> ''",
  :group      => "host_os, ruby_version, user_key")

grouping = Grouping(table, :by => "host_os")

ruby_versions = Table(%w[platform ruby_version count])  

grouping.each do |name,group|
  Grouping(group, :by => "ruby_version").each do |vname,group|
    ruby_versions << { "platform"         => name, 
                       "ruby_version"     => vname,
                       "count"            => group.length }
  end
end

sorted_table = ruby_versions.sort_rows_by { |r| -r.count }
g = Grouping(sorted_table, :by => "platform")

File.open("platforms_ruby.html", "w") do |f|
  f.write g.to_html(:style => :justified)
end
