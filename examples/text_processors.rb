require "ruport"

class MyReport < Ruport::Report
  prepare {
    self.results = "Foo Bar Baz"
    text_processor(:replace_foo) { |r| r.gsub(/Foo/,"Ruport") }
    text_processor(:replace_bar) { |r| r.gsub(/Bar/,"Is") }
    text_processor(:replace_baz) { |r| r.gsub(/Baz/, "Cool!") }
  }
  generate {
    process_text results, :filters => [:replace_foo,:replace_bar,:replace_baz]
  }
end
