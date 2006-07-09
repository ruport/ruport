require "ruport"


class MyReport < Ruport::Report
  prepare {
    self.results = "Foo Bar Baz"
    text_processor(:replace_foo) { results.gsub!(/Foo/,"Ruport") }
    text_processor(:replace_bar) { results.gsub!(/Bar/,"Is") }
    text_processor(:replace_baz) { results.gsub!(/Baz/, "Cool!") }
  }
  generate {
    process_text results, :filters => [:replace_foo,:replace_bar,:replace_baz]
  }
end

MyReport.run { |e| puts e.results }
    


  
