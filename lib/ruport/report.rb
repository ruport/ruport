# report.rb : High Level Interface to Ruport
#
# Author: Gregory Brown
# Copyright 2006, All Rights Reserved
#
# This is Free Software.  See LICENSE and COPYING files for details.

#load the needed standard libraries.
%w[erb yaml date logger fileutils].each { |lib| require lib }
require "forwardable"

module Ruport

  # === Overview
  #
  # The Ruport::Report class provides a high level interface to much of Ruport's
  # functionality.  It is designed to allow you to build and run reports easily.
  # If your needs are complicated, you will probably need to take a look at the
  # individual classes of the library, but if they are fairly simple, you may be
  # able to get away using this class alone. 
  #
  # Ruport::Report is primarily meant to be used with Ruport's code generator, 
  # rope, and is less useful when integrated within another system, such as
  # Rails or Camping.
  #
  # Below is a simple example of loading a report in from a CSV, performing a
  # grouping operation, and then rendering the resulting PDF to file.
  #
  #   require "rubygems"
  #   require "ruport"
  #   class MyReport < Ruport::Report 
  #
  #     renders_as_grouping(:style => :inline)   
  #
  #     def generate
  #       table = load_csv "foo.csv"
  #       Grouping(table, :by => "username")
  #     end  
  #
  #   end   
  #
  #   report = MyReport.new(:pdf) 
  #   report.run { |results| results.write("bar.pdf") }
  #
  class Report   
    extend Forwardable
    include Renderer::Hooks
        
    # Builds a report instance.  If provided a format parameter, 
    # this format will be used by default when rendering the report.
    #
    def initialize( format=nil )
      use_source :default
      @format      = format
      @report_name = "" 
      @results     = ""
      @file        = nil
    end
    
    # By default, this file will be used by Report#write.
    attr_accessor :file

    # This attribute will get the results of Report#generate when the report is
    # run.
    #
    attr_accessor :results
     
    # This attribute defines which format the Report will render in by default.
    attr_accessor :format

    # This is a simplified interface to Ruport::Query.
    #
    # You can use it to read SQL statements from file or string:
    #  
    #   #from string 
    #   result = query "select * from foo"
    #
    #   #from file 
    #   result = query "my_query.sql", :origin => :file
    # 
    # You can use multistatement SQL:
    #
    #   # will return the value of the last statement, "select * from foo"
    #   result = query "insert into foo values(1,2); select * from foo"
    # 
    # You can iterate by row:
    #  
    #   query("select * from foo") { |r|
    #     #do something with the rows here
    #   }
    # 
    # query() can return raw DBI:Row objects or Ruport's data structures:
    # 
    #   # will return an Array of DBI::Row objects
    #   result = query "select * from foo", :raw_data => true
    #
    # You can quickly output in a number of formats:
    # 
    #   result = query "select * from foo", :as => :csv
    #   result = query "select * from foo", :as => :html
    #   result = query "select * from foo", :as => :pdf
    #
    # See Ruport::Query for details.
    #
    def query(sql, options={})
      options[:origin] ||= :string
      options[:source] ||= @source
      q = options[:query_obj] || Query.new(sql, options)
      if block_given?
        q.each { |r| yield(r) }
      elsif options[:as]
        q.result.as(options[:as])
      else
        q.result
      end
    end
    
    # Sets the active source to the Ruport::Query source requested by
    # <tt>label</tt>. 
    #
    # For example, if you have a data source :test, which is defined as such:
    #
    #   Ruport::Query.add_source(:test, :dsn => "dbi:mysql:test", 
    #                                   :user => "root" ) 
    #
    #  
    # The following report would use that data source rather than the
    # <tt>:default</tt> source:
    #
    #   class MyReport < Ruport::Report
    #
    #     renders_as_table     
    #
    #     def generate
    #        use_source :test
    #        query "select * from foo" 
    #     end             
    #
    #   end
    def use_source(label)
      @source = label
    end
     
    # Writes the contents of Report#results to file.
    # If given a string as a second argument, writes that to file, instead.
    #
    # Examples:
    #   
    #   # write the results of the report to a file
    #   Report.run { |r| r.write("foo.txt") } 
    #   
    #   # write the results in reverse     
    #   Report.run { |r| r.write("foo.txt",r.results.reverse) }     
    #    
    def write(my_file=file,my_results=results)
      File.open(my_file,"w") { |f| f << my_results }
    end
    
    # Behaves the same way as Report#write, but will append to a file rather
    # than create a new file if it already exists.
    #
    def append(my_file=file,my_results=results)
      File.open(my_file,"a") { |f| f << my_results }
    end
    
    # This method passes <tt>self</tt> to Report.run.
    #
    # Please see the class method for details.
    #
    def run(options={},&block)
      options[:reports] ||= [self]
      self.class.run(options,&block)
    end
       
    # Allows you to override the default format.
    #
    # Example:
    #
    #   my_report.as(:csv) 
    #
    def as(format,*args)   
      self.format,old = format, self.format
      results = run(*args)  
      self.format = old 
      return results
    end
                                 
    # Provides syntactic sugar, allowing to_foo in place of as(:foo)
    def method_missing(id,*args) 
      id.to_s =~ /^to_(.*)/
      $1 ? as($1.to_sym,*args) : super
    end

    # Loads a CSV in from  a file.
    #
    # Example:
    #
    #   my_table = load_csv "foo.csv"                 #=> Data::Table
    #   my_array = load_csv "foo.csv", :as => :array  #=> Array
    #
    # See also Ruport::Data::Table.load and Table()
    #
    def load_csv(file,options={})
      case options[:as]
      when :array
        a = []
        Data::Table.load(file,options) { |s,r| a << r } ; a
      else
        Data::Table.load(file,options)
      end
    end

    # Executes an erb template.  If a filename is given which matches the
    # pattern /\.r\w+$/ (eg foo.rhtml, bar.rtxt, etc), 
    # it will be loaded and evaluated.  Otherwise, the string will be processed
    # directly.
    #
    # Examples:
    #
    #  @foo = 'greg'
    #  erb "My name is <%= @foo %>" #=> "My name is greg"
    #
    #  erb "foo.rhtml" #=> contents of evaluated text in foo.rhtml
    #
    def erb(s)
      if s =~ /\.r\w+$/
        ERB.new(File.read(s)).result(binding)
      else
        ERB.new(s).result(binding)
      end
    end

    class << self
      
      # Allows you to override the default format.
      #
      # Example:
      #
      #   my_report.as(:csv) 
      #
      def as(format,options={})
        report = new(format)
        report.run(rendering_options.merge(options))
      end 
      
      # Provides syntactic sugar, allowing to_foo in place of as(:foo)        
      def method_missing(id,*args) 
        id.to_s =~ /^to_(.*)/
        $1 ? as($1.to_sym,*args) : super
      end

      # Defines an instance method which will be run before the
      # <tt>generate</tt> method when Ruport.run is executed.
      #
      # Good for setting config info and perhaps files and/or loggers.
      #
      def prepare(&block); define_method(:prepare,&block) end
      
      # Defines an instance method which will be executed by Report.run.
      #
      # The return value of this method is assigned to the <tt>results</tt>
      # attribute.
      #
      def generate(&block); define_method(:generate,&block) end
      
      # Defines an instance method which will be executed after the object is
      # yielded in Report.run.
      #
      def cleanup(&block); define_method(:cleanup,&block) end

      private :prepare, :generate, :cleanup

      # Runs the reports specified.  If no reports are specified, then it
      # creates a new instance via <tt>self.new</tt>.
      #
      # Hooks called, in order:
      #    * Report#prepare
      #    * Report#generate #=> return value stored in @results
      #    * yields self to block, if given   
      #    * if a renderer is specified, passes along @results and options
      #    * Report#cleanup    
      #
      # Options: 
      #   :reports:  A list of reports to run, defaults to a single generic
      #              instance of the current report (self.new).  
      # 
      #   :tries:, :timeout:, :interval:   Wrappers on attempt.rb
      # 
      #    all other options will be forwarded to a renderer if one is specified
      #    via the Renderer::Hooks methods
      def run(options={})
        options[:reports] ||= [self.new]

        formatting_options = ( options.keys - 
                                [:reports,:tries,:timeout,:interval])

        fopts = formatting_options.inject({}) { |s,k|
          s.merge( k => options[k] )
        }
        

        process = lambda do
          options[:reports].each { |rep|
            rep.prepare if rep.respond_to? :prepare
            rep.results = rep.generate

            if renderer
              rep.results = 
                renderer.render(rep.format,rendering_options.merge(fopts)) { |r| 
                r.data = rep.results
              }
            end

            yield(rep) if block_given?
            rep.cleanup if rep.respond_to? :cleanup
          }
        end

        if options[:tries] && (options[:interval] || options[:timeout])
          code = Attempt.new { |a| 
            a.tries = options[:tries]
            a.interval = options[:interval] if options[:interval]
            a.timeout = options[:timeout] if options[:timeout]
          }
          code.attempt(&process)
        else
          process.call
        end

        outs = options[:reports].map { |r| r.results }
        if outs.length == 1
          outs.last
        else
          outs
        end
        
      end
    end
  end
end
