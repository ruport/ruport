$LOAD_PATH.unshift(File.dirname(__FILE__) + "/../lib/")
require "ruport"

# build up a Table - this could be built in a range of ways
# Check the API documentation and recipe book for more information
data = [[1,4,7,9], [6,2,3,0]].to_table(%w[a b c d])

# Build the report object
report = Ruport::Format.table_object(:plugin => :latex, :data => data)

# By default, the latex plugin will return plain text latex source
# changing the format option asks Ruport to attempt to render
# the source into a PDF using pdflatex
report.options = { :format => :pdf }

# save the resulting report to a file on the filesystem
File.open( "table.pdf","w") { |f| f.puts report.render }
