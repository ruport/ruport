require "lib/init"
class Playlist < Ruport::Report
  
  def prepare
    t = load_csv "data/mix.txt", :csv_options => { :col_sep => "\t" }
    @table = t.sub_table(%w[Name Artist Album Time])
  end
 
  def generate
    @table.to_pdf
  end

end

if __FILE__ == $0
   Playlist.run { |res| res.write 'output/mix.pdf'}
end
