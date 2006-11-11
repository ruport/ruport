# report.rb : High Level Interface to Ruport
#
# Author: Gregory Brown
# Copyright 2006, All Rights Reserved
#
# This is Free Software.  See LICENSE and COPYING files for details.

#load the needed standard libraries.
%w[erb yaml date logger fileutils].each { |lib| require lib }
%w[graph].each { |lib| require "ruport/report/"+lib }
require "forwardable"

module Ruport

  # === Overview
  #
  # The Ruport::Report class povides a high level interface to most of Ruport's
  # functionality.  It is designed to allow you to build and run reports easily.
  # If your needs are complicated, you will probably need to take a look at the
  # individual classes of the library, but if they are fairly simple, you may be
  # able to get away using this class alone.
  #
  # === Example
  #
  # Here is a simple example of using the Report class to run a simple query and
  # then email the results as a CSV file, deleting the file from the local
  # machine after it has been emailed:
  #
  #  require "ruport"
  #  require "fileutils"
  #  class MyReport < Ruport::Report
  #    prepare do
  #      log_file "f.log"
  #      log "preparing report", :status => :info
  #      source :default, 
  #        :dsn => "dbi:mysql:foo", 
  #        :user => "root"
  #      mailer :default,
  #        :host => "mail.adelphia.net", 
  #        :address => "gregory.t.brown@gmail.com"
  #    end
  #      
  #    generate do
  #      log "generated csv from query", :status => :info
  #      query "select * from bar", :as => :csv 
  #    end
  #
  #    cleanup do
  #      log "removing foo.csv", :status => :info
  #      FileUtils.rm("foo.csv") 
  #    end
  #  end
  #
  #  MyReport.run { |res| 
  #    res.write "foo.csv";
  #    res.send_to("greg7224@gmail.com") do |mail|
  #      mail.subject = "Sample report" 
  #      mail.attach "foo.csv"
  #      mail.text = <<-EOS
  #        this is a sample of sending an emailed report from within Ruport.
  #      EOS
  #    end
  #  } 
  #
  # 
  # This class can also be used to run templates and process text filters
  #
  # See the examples in the documentation below to see how to use these
  # features. (Namely Report#process_text , Report#text_processor, and
  # Report#eval_template )
  #
  class Report   
    extend Forwardable
    
    include Ruport::Data::TableHelper
    # When initializing a report, you can provide a default mailer and source by
    # giving a name of a valid source or mailer you've defined via
    # Ruport::Config
    #
    # If your report does not need any sort of specialized information, you can
    # simply use Report.run (Or MyReportName.run if you've inherited)
    #
    # This will auto-initialize a report.
    def initialize( source_name=:default, mailer_name=:default )
      use_source source_name
      use_mailer mailer_name
      @report_name = "" 
      @results     = ""
      @file        = nil
    end
    
    #by default, this file will be used by Report#write
    attr_accessor :file

    #this attribute will get the results of Report#generate when the report is
    #run.
    attr_accessor :results

    # Simplified interface to Ruport::Query
    #
    # === Can read SQL statements from file or string
    #  
    #  #from string 
    #  result = query "select * from foo"
    #
    #  #from file 
    #  result = query "my_query.sql", :origin => :file
    # 
    # === Can use multistatement SQL
    #
    #  # will return the value of the last statement, "select * from foo"
    #  result = query "insert into foo values(1,2); select * from foo"
    # 
    # === Can iterate by row or return entire set
    #  
    #  query("select * from foo", :yield_type => :by_row) { |r|
    #     #do something with the rows here
    #  }
    # 
    # === Can return raw DBI:Row objects or Ruport's data structures.
    # 
    #  # will return an Array of DBI::Row objects
    #  result = query "select * from foo", :raw_data => true
    #
    # === Can quickly output in a number of formats
    # 
    #  result = query "select * from foo", :as => :csv
    #  result = query "select * from foo", :as => :html
    #  result = query "select * from foo", :as => :pdf
    #
    # See source of this function and methods of Ruport::Query for details.
    def query(sql, options={})
      options[:origin] ||= :string
      options[:source] ||= @source
      options[:binding] ||= binding
      q = options[:query_obj] || Query.new(sql, options)
      if options[:yield_type].eql?(:by_row)
        q.each { |r| yield(r) }
      elsif options[:as]
        Format.table :data => q.result, :plugin => options[:as]
      else
        block_given? ? yield(q.result) : q.result
      end
    end
   
    # FIXME: Sucks!
    # Evaluates _code_ from _filename_ as pure ruby code for files ending in
    # .rb, and as ERb templates for anything else.
    #
    # This code will be evaluated in the context of the instance on which it is
    # called.
    def eval_template( code, filename=nil )
      filename =~ /\.rb/ ? eval(code) : ERB.new(code, 0, "%").result(binding)
    end
   
    # sets the active source to the Ruport::Config source requested by label.
    def use_source(label)
      @source = label
    end

    # sets the active mailer to the Ruport::Config source requested by label.
    def use_mailer(label)
      @mailer = label
    end
    
    # Provides a nice way to execute templates and filters.
    #
    # Example:
    #
    #  process_text "_<%= @some_internal_var %>_", :filters => [:erb,:red_cloth]
    #
    # This method automatically passes a binding into the filters, so you are
    # free to access data from your Report instance in your templates.
    def process_text(string, options)
      options[:filters].each do |f|
        format = Format.new(binding)
        format.content = string
        string = format.send("filter_#{f}")
      end
      string
    end
    
    # This allows you to create filters to be used by process_text
    #
    # The block is evaluated in the context of the instance.
    #
    # E.g
    #
    #  text_processor(:unix_newlines) { |r| r.gsub(/\r\n/,"\n") }
    def text_processor(label,&block)
      Format.register_filter(label, &block)
    end


    # Writes the contents of <tt>results</tt> to file.  If a filename is
    # specified, it will use it.  Otherwise, it will try to write to the file
    # specified by the <tt>file</tt> attribute.
    def write(my_file=file,my_results=results)
      File.open(my_file,"w") { |f| f << my_results }
    end

    # Like Report#write, but will append to a file rather than overwrite it if
    # the file already exists
    def append(my_file=file)
      File.open(my_file,"a") { |f| f << results }
    end

    class << self

      # Defines an instance method which will be run before the
      # <tt>generate</tt> method when Ruport.run is executed
      #
      # Good for setting config info and perhaps files and/or loggers
      #
      def prepare(&block); define_method(:prepare,&block) end
      
      # Defines an instance method which will be executed by Report.run
      #
      # The return value of this method is assigned to the <tt>results</tt>
      # attribute
      #
      def generate(&block); define_method(:generate,&block) end
      
      # Defines an instance method which will be executed after the object is
      # yielded in Report.run 
      #
      def cleanup(&block); define_method(:cleanup,&block) end
      
      # Runs the reports specified.  If no reports are specified, then it
      # creates a new instance via <tt>self.new</tt>
      #
      # Tries to execute the prepare instance method, then runs generate.
      # It then yields the object so that you may do something with it
      # (print something out, write to file, email, etc)
      # 
      # Finally, it tries to call cleanup.
      def run(options={})
        options[:reports] ||= [self.new]

        process = lambda do
          options[:reports].each { |rep|
            rep.prepare if rep.respond_to? :prepare
            rep.results = rep.generate
            yield(rep) if block_given?
            rep.cleanup if rep.respond_to? :cleanup
          }
        end

        if options[:tries] && (options[:interval] || options[:timeout])
          code = Attempt.new { |a| 
            a.tries = options[:tries]
            a.interval = options[:interval] if options[:interval]
            a.timeout = options[:timeout] if options[:timeout]
            a.log_level = options[:log_level]
          }
          code.attempt(&process)
        else
          process.call
        end
      end

    end

    # this method passes <tt>self</tt> to Report.run 
    #
    # Please see the class method for details.
    def run(options={},&block)
      options[:reports] ||= [self]
      self.class.run(options,&block)
    end


    # loads a CSV in from file.
    #
    # Example
    #
    # my_table = load_csv "foo.csv" #=> Data::Table
    # my_array = load_csv "foo.csv", :as => :array #=> Array
    #
    # See also, Ruport::Data::Table.load
    def load_csv(file,options={})
      case options[:as]
      when :array
        a = []
        Data::Table.load(file,options) { |s,r| a << r } ; a
      else
        Data::Table.load(file,options)
      end
    end
    
    # Allows logging and other fun stuff. See Ruport.log
    def log(*args); Ruport.log(*args) end
   
    # Creates a new Mailer and sets the <tt>to</tt> attribute to the addresses
    # specified.  Yields a Mailer object, which can be modified before delivery.
    #
    def send_to(adds)
      m = Mailer.new
      m.to = adds
      yield(m)
      m.send(:select_mailer,@mailer)
      m.deliver :from => m.from, :to => m.to
    end
    
    def_delegators Ruport::Config, :source, :mailer, :log_file, :log_file=
    
  end

end


