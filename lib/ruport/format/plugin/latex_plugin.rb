module Ruport
  class Format::Plugin
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

        @report_header + @body + @report_footer
      end

      plugin_name :latex
      register_on :table_engine

    end
  end
end
