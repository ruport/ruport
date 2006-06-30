# fixME: Copyright notice here.

#load the needed standard libraries.
%w[erb yaml date logger fileutils].each { |lib| require lib }

require "ruport/mailer"

module Ruport
  class Report   
    def initialize( source_name=:default, mailer_name=:default )
      @source = source_name
      @report_name = @report = ""
      @file        = nil
    end
    
    attr_accessor :file,:report
    
    # High level interface to Ruport::Query
    # - Can read SQL statements from file or string
    # - Can use multistatement SQL 
    # - Can iterate by row or return entire set
    # - Can return raw DBI:Row objects or Ruport constructs.
    #
    # Defaults to returning entire sets of Ruport constructs.
    #
    # See source of this function and methods of Ruport::Query for details.
    def query(sql, options={}, &action)
      options[:origin] ||= :string
      options[:source] ||= @source

      q = Query.new(sql, options)
      if options[:yield_type].eql?(:by_row)
        q.each { |r| action.call(r) }
      else
        block_given? ? action.call(q.result) : q.result
      end
    end
    
    # Evaluates _code_ from _filename_ as pure ruby code for files ending in
    # .rb, and as ERb templates for anything else.
    def eval_template( filename, code )
      filename =~ /\.rb/ ? eval(code) : ERB.new(code, 0, "%").run(binding)
    end
    

    # Generates the report.  If @pre or @post are defined with lambdas,
    # they will be called before and after the main code.
    #
    # If @file != nil, ruport will print to the
    # file with the specified name.  Otherwise, it will print to STDOUT by
    # default. 
    #
    # The source for this function is probably easier to read than this
    # explanation, so you may want to start there.     
    def generate_report
      @pre.call if @pre
      @file ? File.open(@file,"w") { |f| f.puts @report } : puts(@report)
      @post.call if @post
    end

    # sets the active source to the Ruport::Config source requested by label.
    def use_source(label)
      @source = label
    end
    
    # Provides a nice way to execute templates and filters.
    #
    # Example:
    #
    #   my_report.render( "_<%= @some_internal_var %>_", 
    #                     :filters => [:erb,:red_cloth] )
    #
    # This method automatically passes a binding into the filters, so you are
    # free to access data from your Report instance in your templates.
    def render(string, options)
      options[:filters].each do |f|
        format = Format.new(binding)
        format.content = string
        string = format.send("filter_#{f}")
      end
      string
    end


  end
end


