#################################################################
# This example shows how to build custom PDF output with Ruport #
# that shares some common elements between reports.  Basically, #
# CompanyPDFBase implements some default rendering options,     #
# and derived classes such as ClientPDF would implement the     #
# stuff specific to a given report.                             #
#################################################################
                         
require "ruport" 

# only used for the titleize call in ClientController#setup  
# tweak as needed if you don't want to install AS.
require "active_support" 

# This looks a little more messy than usual, but it addresses the
# concern of wanting to have a standard template for reports.
#
class ClientController < Ruport::Controller
  prepare :standard_report
  stage :company_header, :client_header, :client_body, :client_footer
  finalize :standard_report

  def setup
    data.rename_columns { |c| c.to_s.titleize }
  end 
end

# This defines the base PDF output, you'd do similar for other
# formats if needed. It implements the common hooks that will be used
# across the company's reports. 
#
class CompanyPDFBase < Ruport::Formatter::PDF
  def prepare_standard_report 
    # defaults to US Letter, but this overrides
    options.paper_size = "A4"
  end

  def build_company_header
    add_text "This would be my company header",
             :justification => :center, :font_size => 14
  end

  def finalize_standard_report
    render_pdf
  end
end

#  This is actual report's formatter
#
#  It implements the remaining hooks the standard formatter didn't
#  Notice the footer is not implemented and it doesn't complain.   
#
class ClientPDF < CompanyPDFBase
  renders :pdf, :for => ClientController

  def build_client_header
   pad(10) do
    add_text "Specific Report Header with example=#{options.example}",
             :justification => :center, :font_size => 12
   end
  end

  def build_client_body
    draw_table(data, :width => 300)
  end 
end

table = Table([:a,:b,:c]) << [1,2,3] << [4,5,6]

File.open("example.pdf","w") do |f|
  f << ClientController.render_pdf(:data => table,:example => "apple")
end
