module Ruport::Format
  class Latex < Plugin #:nodoc:

    attr_accessor :caption
   
    def build_table_header
      output << "\\documentclass[11pt]{article}\n"     <<
                "\\RequirePackage{lscape,longtable}\n" <<
                "\\begin{document}\n" <<
                "\\begin{longtable}[c]{ "
        
        data.column_names.each do
          output << " p{2cm} "
        end
        output << " }\n"
        output << "\\hline\n"

        output << "\\textsc{#{data.column_names[0]}}"
        data.column_names[1..-1].each do |t|
          output << " & "
          output << "\\textsc{#{t}}"
        end

        output << "\\\\\n"
        output << "\\hline\n"
        output << "\\endhead\n"
        output << "\\endfoot\n"
        output << "\\hline\n"
    end

    def build_table_body
      data.each do |r|
        Ruport::Renderer::Row.render_latex { |rend|
          rend.data = r 
          rend.io = output
        }
      end
      if caption
        output << "\\caption[#{caption}]{#{caption}}\n"
      end
      output << "\\end{longtable}\n"
    end

    def build_table_footer
      output << "\\end{document}\n"
    end

    def build_row
      output << data.to_a.join(" & ") + "\\\\\n"
      output << "\\hline\n"
    end

  end
end
