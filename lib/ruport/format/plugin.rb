require 'bigdecimal'
require 'tempfile'

class RenderingError < RuntimeError; end

module Ruport
  class Format::Plugin

    class << self

      attr_accessor :data
      attr_accessor :options 
      
      include MetaTools

      def helper(name,options={},&block)
        if options[:engines]
          options[:engines].each { |e| 
            helpers[e].send(:define_method, "#{name}_helper", &block)
          }
        elsif options[:engine]
          helpers[options[:engine]].send(  :define_method, 
                                         "#{name}_helper", &block)
        else
          singleton_class.send( :define_method, "#{name}_helper", &block )
        end
      end

      def helpers
        @helpers ||= Hash.new { |h,k| h[k] = Module.new }
      end

      private :singleton_class, :attribute, :attributes, :action
     
      def plugin_name(name=nil); @name ||= name; end
      
      def renderer(render_type,&block)
        m = "render_#{render_type}".to_sym
        block ||= lambda { data } 
        singleton_class.send(:define_method, m, &block)
      end

      def format_field_names(&block)
        singleton_class.send( :define_method, :build_field_names, &block)
      end

      def register_on(klass)
        
        if klass.kind_of? Symbol
          klass = Format::Engine.engine_classes[klass]
        end
        
        klass.accept_format_plugin(self)
      end
      
      def rendering_options(hash={})
        @options ||= {}
        @options.merge!(hash)
        @options.dup
      end
     
      attr_accessor :rendered_field_names
      attr_accessor :pre, :post
      attr_accessor :header, :footer
   end
    
    
    class CSVPlugin < Format::Plugin
      
      helper(:init_plugin) { |eng| require "fastercsv" }

      format_field_names do
        FasterCSV.generate { |csv| csv << data.column_names }
      end
      
      renderer :table do
        rendered_field_names +
        FasterCSV.generate { |csv| data.each { |r| csv << r } }
      end
      
      plugin_name :csv
      register_on :table_engine
    end

    class LatexPlugin < Format::Plugin
    
      helper(:init_plugin) { |eng|
        @report_header = "\\documentclass[11pt]{article}\n"
        @report_header << "\\RequirePackage{lscape,longtable}\n"
        @report_header << "\\begin{document}\n"

        @report_footer = "\\end{document}\n"
      }

      renderer :table do 
        self.options = {} if self.options.nil?

        @body = "\\begin{longtable}[c]{ "
        @data.column_names.each do
          @body << " p{2cm} "
        end
        @body << " }\n"
        @body << "\\hline\n"
        counter = 0
        @data.column_names.each do |t|
          @body << " & " unless counter == 0
          @body << "\\textsc{#{t}}"
          counter += 1
        end
        @body << "\\\\\n"
        @body << "\\hline\n"
        @body << "\\endhead\n"
        @body << "\\endfoot\n"
        @body << "\\hline\n"
        @data.each do |r|
          @body << r.data.join(" & ") + "\\\\\n"
          @body << "\\hline\n"
        end
        unless options[:caption].nil?
          @body << "\\caption[#{options[:caption]}]{#{options[:caption]}}\n"
        end
        @body << "\\end{longtable}\n"

        if options[:format] == :pdf
          generate_pdf
        else
          @report_header + @body + @report_footer
        end
      end
     
      # much of the code in this method is derived from the rtex rails plugin, written
      # by Bruce Williams.
      # http://codefluency.com/code/rtex-rails-plugin/
      action :generate_pdf do

        temp = Tempfile.new('ruport')
        temp.binmode # For Windows
        temp.puts @report_header + @body + @report_footer
        temp.close
        latex_return = ''
        Dir.chdir(File.dirname(temp.path)) do
          latex_return = `pdflatex --interaction=nonstopmode '#{temp.path}'`
        end

        pdfpath = temp.path.sub(/\..*?$/,'')+'.pdf'
      
        File.unlink temp.path.sub( /\..*?$/,'.aux')
        File.unlink temp.path.sub( /\..*?$/,'.log')

        if File.exists?(pdfpath)
          return File.open(pdfpath,'rb'){ |f| f.read }
          #FIXME: the line below will never be executed
          File.unlink pdfpath
        else
          raise RenderingError, "Could not generate PDF:\n#{latex_return}"      
        end
      end

      plugin_name :latex
      register_on :table_engine
    end

    class SVGPlugin < Format::Plugin
      
      helper(:init_plugin) { |eng|
        # check the supplied data can be used for graphing
        data.each { |r|
          if data.column_names.size != r.data.size
            raise ArgumentError, "Column names and data do not match"           
          end 
          r.data.each { |c|
            begin
              c = BigDecimal.new(c) unless c.kind_of?(Float) || 
                c.kind_of?(Fixnum) || c.kind_of?(BigDecimal)
            rescue
              raise ArgumentError, "Unable to convert #{c.to_s} into a number" 
            end
          }
        }
        
        raise RuntimeError, 'You must provide an options hash before rendering a graph' if self.options.nil?

        # load the appropriate SVG::Graph class based on the graph_style option
        case options[:graph_style]
        when :bar
          require "SVG/Graph/Bar"
          graphclass = SVG::Graph::Bar
        when :bar_horizontal
          require "SVG/Graph/BarHorizontal"
          graphclass = SVG::Graph::BarHorizontal
        when :line
          require "SVG/Graph/Line" 
          graphclass = SVG::Graph::Line
        when :pie
          require "SVG/Graph/Pie" 
          graphclass = SVG::Graph::Pie
        else
          raise "Unsupported graph type requested"
        end

        # create an instance of the graphing class
        options[:fields] = data.column_names
        @graph = graphclass.new(options)
      }

      renderer :graph do
        
        data.each_with_index { |r,i|
          @graph.add_data({
            :data => r.data,
            :title => r.tags[0] || 'series ' + (i+1).to_s
          })
        }
        
        # return the rendered graph
        @graph.burn()
      end
      
      plugin_name :svg
      register_on :graph_engine
    end
    
    class TextPlugin < Format::Plugin
      rendering_options :erb_enabled => true, :red_cloth_enabled => false

      renderer :document
      
      renderer :table do 
        require "ruport/system_extensions" 
        
        th = "#{rendered_field_names}#{hr}"
       
        data.each { |r|
          r.each_with_index { |f,i|
            r[i] = f.to_s.center(max_col_width(i))
          }
        }
        
        a = data.inject(th){ |s,r|
          s + "| #{r.to_a.join(' | ')} |\n"
        } << hr

        width = self.right_margin || SystemExtensions.terminal_width
        
        a.to_a.each { |r|
           r.gsub!(/\A.{#{width+1},}/) { |m| m[0,width-2] + ">>" }
        }.join
      end
      
      format_field_names do
        data.column_names.each_with_index { |f,i| 
          data.column_names[i] = f.to_s.center(max_col_width(i))
        }
        "#{hr}| #{data.column_names.to_a.join(' | ')} |\n"
      end

      action :max_col_width do |index|
        f = data.column_names if data.respond_to? :column_names
        d = Data::Table.new :column_names => f, :data => data
        
        cw = d.map { |r| r[index].to_s.length }.max
        
        return cw unless d.column_names
        
        nw = (index.kind_of?(Integer) ? d.column_names[index] : index ).to_s.length
        
        [cw,nw].max
      end

      action :table_width do
        f = data.column_names if data.respond_to? :column_names
        d = Data::Table.new:column_names => f, :data => data 

        f = d[0].attributes || (0...d[0].length)

        f.inject(0) { |s,e| s + max_col_width(e) }
      end

      action :hr do
        len = data[0].to_a.length * 3 + table_width + 1
        "+" + "-"*(len-2) + "+\n"
      end

      attribute :right_margin
      plugin_name :text
      register_on :table_engine
      register_on :document_engine
    end

    class PDFPlugin < Format::Plugin
      attribute :pdf
      attribute :paper

      helper(:init_plugin) {
        require "pdf/writer"
        require "pdf/simpletable"
        self.pdf = PDF::Writer.new( :paper => paper || "LETTER" )
      }

      renderer :table do
        pre[pdf] if pre
        PDF::SimpleTable.new do |table|
          table.maximum_width = 500
          table.orientation = :center
          table.data = data
          m = "Sorry, cant build PDFs from array like things (yet)"      
          raise m if self.rendered_field_names.empty? 
          table.column_order = self.rendered_field_names
          table.render_on(pdf)
        end
        post[pdf] if post
        pdf.render
      end

      format_field_names { data.column_names }
      
      renderer(:invoice) { pdf.render }

      # Company Information in top lefthand corner
      helper(:build_company_header, :engine => :invoice_engine) { |eng| 
        @tod = pdf.y
        text_box(eng.company_info)
      }

      helper(:build_headers, :engine => :invoice_engine) { |eng|
        build_company_header_helper(eng)
        build_customer_header_helper(eng)
        build_title_helper(eng)
        build_order_header_helper(eng)
      }

      helper(:build_order_header, :engine => :invoice_engine) { |eng|
        if eng.order_info
          text_box(eng.order_info, :position => 350)
        end
      }

      helper(:build_title, :engine => :invoice_engine) { |eng|
        pdf.y = @tod
        if eng.title
          pdf.text eng.title, :left => 350, :font_size => 14
          pdf.y -= 10
        end
      }

      helper(:build_footer, :engine => :invoice_engine) { |eng|
        # footer
        pdf.open_object do |footer|
          pdf.save_state
          pdf.stroke_color! Color::RGB::Black
          pdf.stroke_style! PDF::Writer::StrokeStyle::DEFAULT
          if eng.comments  
            pdf.y -= 20
            text_box eng.comments, :position => 110, :width => 400, 
                                   :font_size => 14
          end
          pdf.add_text_wrap( 50, 20, 200, "Printed at " + 
                             Time.now.strftime("%H:%M %d/%m/%Y"), 8)

          pdf.restore_state
          pdf.close_object
          pdf.add_object(footer, :all_pages)
        end
        pdf.stop_page_numbering(true, :current)
      } 
       
      helper(:build_body, :engine => :invoice_engine) do
       pdf.start_page_numbering(500, 20, 8, :right)
       
        # order contents 
        pdf.y = 620
        
        PDF::SimpleTable.new do |table|
          table.width = 450
          table.orientation = :center
          table.data = data
          table.show_lines = :outer
          table.column_order = data.column_names
          table.render_on(pdf)
          table.font_size = 12
        end
      end

      # Order details
      helper(:build_customer_header, :engine => :invoice_engine) { |eng| 
        pdf.y -= 10
        text_box(eng.customer_info)
      }
     
      def self.text_box(content,options={})
        PDF::SimpleTable.new do |table| 
          table.data = content.to_a.inject([]) do |s,line|
            s << { "value" => line }
          end
          table.column_order = "value"
          table.show_headings = false
          table.show_lines  = :outer
          table.shade_rows  = :none
          table.width       = options[:width] || 200
          table.orientation = options[:orientation] || :right
          table.position = options[:position] || :left
          table.font_size = options[:font_size] || 10
          table.render_on(pdf)
        end
      end
       
      plugin_name :pdf
      register_on :table_engine
      register_on :invoice_engine     
    end

    class HTMLPlugin < Format::Plugin
   
      rendering_options :red_cloth_enabled => true, :erb_enabled => true
      
      renderer :document 
      
      renderer :table do
        rc = data.inject(rendered_field_names) { |s,r| 
          row = r.map { |e| e.to_s.empty? ? "&nbsp;" : e }
          s + "|#{row.to_a.join('|')}|\n" 
        }
        Format.document :data => rc, :plugin => :html 
      end

      format_field_names do
        s = "|_." + data.column_names.join(" |_.") + "|\n"
      end

      plugin_name :html
      register_on :table_engine
      register_on :document_engine
      
    end
            
  end
end
