require "lib/init"

module MyModule
  class SalesRenderer < Ruport::Renderer

     include Ruport::Renderer::Helpers

     required_option :report_title
     required_option :titles

     stage :document_header
     stage :document_body

     finalize :document
  end

  class Text < Ruport::Format::Plugin

    SalesRenderer.add_format self, :txt

    def pad(str, len)
      return "".ljust(len) if str.nil?
      str = str.slice(0, len) # truncate long strings
      str.ljust(len) # pad with whitespace
    end

    def build_document_header
      unless options.report_title.nil?
        output << "".ljust(75,"*") << "\n"
        output << "  #{options.report_title}\n" 
        output << "".ljust(75,"*") << "\n"
        output << "\n"
      end
    end

    def build_document_body
      # table heading
      output << pad("isbn", 15) << "|" << pad("title",30) << "|"
      output << pad("author", 15) << "|" << pad("sales", 10) << "\n"
      output << "".ljust(75,"#") << "\n"

      # table data
      options.titles.each do |title|
        output << pad(title["isbn"],15) << "|"
        output << pad(title["title"],30) << "|"
        output << pad(title["author"],15) << "|"
        output << pad(title["sales"].to_s,10) << "\n"
      end

      output << "".ljust(75,"#") << "\n"
    end

    def finalize_document; output end

  end

  class PDF < Ruport::Format::PDF
    SalesRenderer.add_format self, :pdf

    def add_title( title )  
      rounded_text_box("<b>#{title}</b>") do |o|
        o.fill_color = Color::RGB::Gray80
        o.radius    = 5  
        o.width     = options.header_width || 200
        o.height    = options.header_height || 20
        o.font_size = options.header_font_size || 12
        o.x         = pdf_writer.absolute_right_margin - o.width 
        o.y         = pdf_writer.absolute_top_margin
      end
    end      

    def build_document_header
      add_title( options.report_title ) unless options.report_title.nil?
    end

    def build_document_body
      pad(50) {
        ::PDF::SimpleTable.new do |table|
          table.maximum_width = 500
          table.orientation   = :center
          table.data          = options.titles
          table.column_order  = %w[isbn title author sales]
          table.render_on(pdf_writer)
        end
      }
    end

    def finalize_document
      output << pdf_writer.render
    end 

  end

end

class Sales < Ruport::Report
 
  attr_accessor :books, :format 
 
  def generate
    MyModule::SalesRenderer.render(format) do |r|
      r.report_title = "December 2006 Sales Figures"
      r.titles = books
    end
  end

end

if __FILE__ == $0

  book1 = {"isbn"    => "978111111111", 
           "title"   => "Book Number One", 
           "author"  => "me", "sales" => 10}

  book2 = { "isbn"   => "978222222222", 
            "title"  => "Two is better than one", 
            "author" => "you", "sales" => 267}

  book3 = { "isbn"   => "978333333333", 
            "title"  => "Three Blind Mice", 
            "author" => "John Howard", "sales" => 1}

  book4 = { "isbn"   => "978444444444", 
            "title"  => "The number 4", 
            "author" => "George Bush", "sales" => 1829}

  books = [book1, book2, book3, book4]

  report = Sales.new 

  report.books = books

  [:pdf, :txt].each { |f|
    report.format = f
    report.run { |r| r.write "output/books.#{f}" }
  }

end
