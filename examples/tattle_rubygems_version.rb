# A dump of the database for this example can be found in ./data/tattle.dump

require "active_record"
require "ruport"

# Update with your connection parameters
ActiveRecord::Base.establish_connection(
    :adapter  => 'mysql',
    :host     => 'localhost',
    :username => 'root',
    :database => 'tattle')

class Report < ActiveRecord::Base
  acts_as_reportable
end

table = Report.report_table(:all,
  :only       => %w[host_os rubygems_version user_key],
  :conditions => "user_key is not null and user_key <> ''",
  :group      => "host_os, rubygems_version, user_key")

grouping = Grouping(table, :by => "host_os")

rubygems_versions = Table(%w[platform rubygems_version count])  

grouping.each do |name,group|
  Grouping(group, :by => "rubygems_version").each do |vname,group|
    rubygems_versions << { "platform"         => name, 
                           "rubygems_version" => vname,
                           "count"            => group.length }
  end
end

sorted_table = rubygems_versions.sort_rows_by { |r| -r.count }
g = Grouping(sorted_table, :by => "platform")

File.open("platforms_gems.html", "w") do |f|
  f.write g.to_html(:style => :justified)
end
