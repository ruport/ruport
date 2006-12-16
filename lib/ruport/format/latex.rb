module Ruport::Format
  class Latex < Plugin

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

        #FIXME: this ain't ruby, jh ;)
        counter = 0

        data.column_names.each do |t|
          output << " & " unless counter == 0
          output << "\\textsc{#{t}}"
          counter += 1
        end

        output << "\\\\\n"
        output << "\\hline\n"
        output << "\\endhead\n"
        output << "\\endfoot\n"
        output << "\\hline\n"
    end

    def build_table_body
      data.each do |r|
        output << r.data.join(" & ") + "\\\\\n"
        output << "\\hline\n"
      end
      if caption
        output << "\\caption[#{caption}]{#{caption}}\n"
      end
      output << "\\end{longtable}\n"
    end

    def build_table_footer
      output << "\\end{document}\n"
    end

  end
end
