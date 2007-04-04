# ruport.rb : Ruby Reports top level module
#
# Author: Gregory T. Brown (gregory.t.brown at gmail dot com)
#
# Copyright (c) 2006, All Rights Reserved.
#
# This is free software.  You may modify and redistribute this freely under
# your choice of the GNU General Public License or the Ruby License. 
#
# See LICENSE and COPYING for details
#

module Ruport
  
  VERSION = "0.9.4"
  
  # This method is Ruport's logging and error interface. It can generate 
  # warnings or raise fatal errors, logging +message+ to the file defined by 
  # <tt>Config::log_file</tt>.
  # 
  # You can configure the logging preferences with the +options+ hash. 
  # Available options are:
  #
  # <b><tt>:status</tt></b>::    Sets the severity level. This defaults to 
  #                              <tt>:warn</tt>, which will invoke 
  #                              <tt>Logger#warn</tt>. A status of 
  #                              <tt>:fatal</tt> will invoke 
  #                              <tt>Logger#fatal</tt> and raise an exception.    
  # <b><tt>:output</tt></b>::    Optional 2nd output. By default, <tt>log()</tt>
  #                              will print warnings to <tt>$stderr</tt> in
  #                              addition to <tt>Config::log_file</tt>. You
  #                              can redirect this to any I/O object with this
  #                              option.
  # <b><tt>:level</tt></b>::     Set this to <tt>:log_only</tt> to disable 
  #                              secondary output. If you want to globally 
  #                              override this setting for all calls to 
  #                              <tt>log()</tt> (which can be useful for 
  #                              debugging), you can set 
  #                              <tt>Config.debug_mode</tt>.
  # <b><tt>:exception</tt></b>:: The +Exception+ to throw on failure.  This 
  #                              defaults to +RunTimeError+.
  # 
  def self.log(message, options={})
    options = {:status => :warn, :output => $stderr}.merge(options)
    options[:output].puts "[!!] #{message}" unless 
      options[:level].eql?(:log_only) and not Ruport::Config.debug_mode?
    Ruport::Config::logger.send(options[:status],message) if Config.logger
    if options[:status].eql? :fatal
      raise(options[:raises] || RuntimeError, message) 
    end
  end 

  # This method yields a <tt>Ruport::Config</tt> object, allowing you to 
  # set the configuration options for your application.
  #
  # Example: 
  #
  #   Ruport.configure do |c|
  #
  #     c.source :default, 
  #              :dsn => "dbi:mysql:foo",
  #              :user => "clyde", 
  #              :password => "pman"
  #
  #     c.mailer :default, 
  #              :host => "mail.example.com", 
  #              :address => "inky@example.com"
  #
  #   end
  #
  def self.configure(&block)
    block.call(Ruport::Config)
  end
end

require "enumerator"
require "ruport/attempt" 
require "ruport/config" 
require "ruport/data" 
require "ruport/report"
require "ruport/renderer"  
require "ruport/formatter" 
require "ruport/query" 
require "ruport/mailer"

module Kernel

  
  # quiets warnings for block
  def quiet #:nodoc:
    warnings = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = warnings
    return result
  end

end
