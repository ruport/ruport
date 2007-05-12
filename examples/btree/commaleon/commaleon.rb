require "rubygems"
require "camping"               
require "camping/session"   
gem "ruport", "=0.12.1"
require "ruport" 
require "ruport/extensions"     
   
Camping.goes :Commaleon   

module Commaleon
  include Camping::Session
end 

def Commaleon.create
  Camping::Models::Session.create_schema
end    

module Commaleon::Helpers

  class CSVDiffRenderer < Ruport::Renderer
     stage :diff_report
     option :key, :mcsv, :ccsv  
     
     def setup
        @master_table = Table(:string => mcsv)
        @compare_table = Table(:string => ccsv)
        options.diff_report = Grouping(:by => "issue")                            
        options.diff_report << missing_from_compare            
        options.diff_report << different_from_compare
     end                        
     
     def missing_from_compare 
       missing_data = @master_table.rows_with(key) do |k| 
         missing_keys.include?(k)
       end        
       
       Group("missing from main csv", 
        :data => missing_data, 
        :column_names => @master_table.column_names )  
     end     
                         
     def different_from_compare 
        shared = master_keys & compare_keys  
        m = @master_table.rows_with(key) do |k|
          shared.include?(k)
        end
                
        diff = m.reject do |r|   
          @compare_table.any? { |s| s == r }
        end    
        
        diff.each do |r|
          comp = @compare_table.rows_with(key => r[key])[0]
          r.to_hash.each do |k,v| 
            if r[k] != comp[k]
              r[k] << " ## " << comp[k]
            end
          end
        end
        
        Group("different from main csv", 
              :data => diff, :column_names => @master_table.column_names)
     end
     
     def missing_keys                
        master_keys - compare_keys
     end   
     
     def master_keys
       @master_table.column(key)
     end
     
     def compare_keys
       @compare_table.column(key)
     end
  end   
  
  class CSVDiffFormatter < F([:html,:text,:csv,:pdf], :for => CSVDiffRenderer)
    def build_diff_report  
     html { gussy_up_html }
     render_grouping(options.diff_report, :style => options.style || :inline )  
    end   
    
    def gussy_up_html
      options.diff_report.each do |n,g| 
         g.send(:name=, "<h4>#{n}</h4>")
      end  
    end
  end
  
end

module Commaleon::Controllers      
  
  class Index < R "/"
    def get
      redirect R(CSVDifference)
    end
  end
  
  class CSVDifference < R '/csv_diff'
    def get
      render :get_diff_files
    end     
    
    def post                                   
      @state.mfile = @input.mfile.tempfile.read
      @state.cfile = @input.cfile.tempfile.read
      redirect R(GenerateDiffReport)   
    end
  end   
         
  class GenerateDiffReport < R '/csv_diff/report'      
    def get              
      @id_fields = Table(:string=>@state.mfile).column_names &
                   Table(:string=>@state.cfile).column_names
      render :csv_get_id 
    end                                                        
    
    def post
      @state.key = @input.csv_id  
      @table = CSVDiffRenderer.render_html(:key =>  @state.key,
                                           :mcsv => @state.mfile,
                                           :ccsv => @state.cfile )  
      render :html_diff   
    end
  end
  
  class CSVDiffReportFormatted < R '/csv_diff/report.(.*)'        
     def set_headers(format)
       types = { "csv" => "application/vnd.ms-excel",
                 "pdf" => "application/pdf",
                 "txt" => "text/plain" } 
       @headers["Content-Type"] = types[format]
       @headers["Content-Disposition"] = "attachment; filename=diff.#{format}"
     end   
     
     def get(format)         
       options = { :key  =>  @state.key, 
                   :mcsv => @state.mfile,
                   :ccsv => @state.cfile } 
       
       set_headers(format)                        
       case(format)
       when "csv"
         text CSVDiffRenderer.render_csv(options)  
       when "pdf"
         text CSVDiffRenderer.render_pdf(options.merge(:style => :justified)) 
       when "txt"
         text CSVDiffRenderer.render_text(options)
       else
         text "no format!"
       end                                
     end
  end  
                       
end

module Commaleon::Views
  def get_diff_files
    form :action => "?upload_id=#{Time.now.to_f}", :method => 'post',
         :enctype => 'multipart/form-data' do
      p do                                
        label "Master File: ", :for => "mfile"
        input({:name => "mfile", :type => 'file'})
      end                                             
      p do 
        label "Comparison File: ", :for => "cfile"
        input({:name => "cfile", :type => 'file'})
      end
      p do
        input.newfile! :type => "submit", :value => "Upload"
      end
    end  
  end  
  
  def csv_get_id
   form :method => "post" do
      label "ID column: ", :for => "csv_id"  
      select(:name => "csv_id") do
        @id_fields.each { |f| option(f) }
      end      
      input :type => "submit", :value => "Set ID"
    end
  end  
  
  def html_diff
    text @table   
    hr
    ul do
      li { a "New Diff", :href => R(CSVDifference) }
      li { a "New Key for Diff", :href => R(GenerateDiffReport) }
      li { a "CSV Download", :href => R(CSVDiffReportFormatted,"csv") } 
      li { a "Text Download", :href => R(CSVDiffReportFormatted,"txt") }
      li { a "PDF Download", :href => R(CSVDiffReportFormatted,"pdf") }
    end
  end        
           
end