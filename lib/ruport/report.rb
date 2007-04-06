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
  # The Ruport::Report class provides a high level interface to most of Ruport's
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
  #    def prepare
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
  #    def generate
  #      log "generated csv from query", :status => :info
  #      query "select * from bar", :as => :csv 
  #    end
  #
  #    def cleanup
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
  class Report   
    extend Forwardable
    
    # When initializing a report, you can provide a default mailer and source by
    # giving a name of a valid source or mailer you've defined via
    # Ruport::Config.
    #
    # If your report does not need any sort of specialized information, you can
    # simply use Report.run (Or MyReportName.run if you've inherited).
    #
    # This will auto-initialize a report.
    #
    def initialize( format=nil, options={} )
      use_source :default
      use_mailer :default
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
      options[:binding] ||= binding
      q = options[:query_obj] || Query.new(sql, options)
      if block_given?
        q.each { |r| yield(r) }
      elsif options[:as]
        q.result.as(options[:as])
      else
        q.result
      end
    end
    
    # Sets the active source to the Ruport::Config source requested by <tt>label</tt>.
    def use_source(label)
      @source = label
    end

    # Sets the active mailer to the Ruport::Config source requested by <tt>label</tt>.
    def use_mailer(label)
      @mailer = label
    end
    
    # Writes the contents of <tt>results</tt> to a file.  If a filename is
    # specified, it will use it.  Otherwise, it will try to write to the file
    # specified by the <tt>file</tt> attribute.
    #
    def write(my_file=file,my_results=results)
      File.open(my_file,"w") { |f| f << my_results }
    end

    # Like Report#write, but will append to a file rather than overwrite it if
    # the file already exists.
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

    def as(format,*args)
      self.format = format
      run(*args)
    end

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
    # See also Ruport::Data::Table.load
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

    # uses RedCloth to turn a string containing textile markup into HTML.
    #
    # Example:
    #
    #   textile "*bar*" #=> "<p><strong>foo</strong></p>"
    #
    def textile(s)   
      require "redcloth"
      RedCloth.new(s).to_html   
    rescue LoadError
      raise RuntimeError, "You need RedCloth!\n gem install RedCloth -v 3.0.3"
    end

    def config
      Ruport::Config
    end
    
    # Allows logging and other fun stuff. 
    # See also Ruport.log
    #
    def log(*args); Ruport.log(*args) end

=begin
    # Creates a new Mailer and sets the <tt>to</tt> attribute to the addresses
    # specified. Yields a Mailer object, which can be modified before delivery.
    #
    def send_to(adds)
      m = Mailer.new
      m.to = adds
      yield(m)
      m.send(:select_mailer,@mailer)
      m.deliver :from => m.from, :to => m.to
    end
=end    

    def_delegators Ruport::Config, :source, :mailer, :log_file, :log_file=
    
    class << self

      def as(format,*args)
        report = new(format)
        report.run(*args)
      end

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

      def renders_with(renderer)
        @renderer = renderer.name
      end


      def renderer
        return unless @renderer
        @renderer.split("::").inject(Class) { |c,el| c.const_get(el) }
      end

      # Runs the reports specified.  If no reports are specified, then it
      # creates a new instance via <tt>self.new</tt>.
      #
      # Tries to execute the prepare instance method, then runs generate.
      # It then yields the object so that you may do something with it
      # (print something out, write to file, email, etc.).
      # 
      # Finally, it tries to call cleanup.
      #
      # This method will return the contents of Report#results, as a single
      # value for single reports, and an array of outputs for multiple reports.
      #
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
              rep.results = renderer.render(rep.format,fopts) { |r| 
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
            a.log_level = options[:log_level]
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
