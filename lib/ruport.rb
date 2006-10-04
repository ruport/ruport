# ruport.rb : Ruby Reports toplevel module
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
  
  VERSION = "0.6.99"
  
  # Ruports logging and error interface.
  # Can generate warnings or raise fatal errors
  # 
  # Takes a message to display and a set of options.
  # Will log to the file defined by Config::log_file
  #
  # Options:
  # <tt>:status</tt>::    sets the severity level. defaults to <tt>:warn</tt>
  # <tt>:output</tt>::    optional 2nd output, defaults to <tt>$stderr</tt>
  # <tt>:level</tt>::     set to <tt>:log_only</tt> to disable secondary output
  # <tt>:exception</tt>:: exception to throw on fail.  Defaults to RunTimeError
  # 
  # The status <tt>:warn</tt> will invoke Logger#warn.  A status of
  # <tt>:fatal</tt> will invoke Logger#fatal and raise an exception
  # 
  # By default, <tt>log()</tt> will also print warnings to $stderr
  # You can redirect this to any I/O object via <tt>:output</tt>
  #
  # You can prevent messages from appearing on the secondary output by setting
  # <tt>:level</tt> to <tt>:log_only</tt>
  # 
  # If you want to recover these messages to secondary output for debugging, you
  # can use Config::enable_paranoia 
  def self.log(message,options={})
    options = {:status => :warn, :output => $stderr}.merge(options)
    options[:output].puts "[!!] #{message}" unless 
      options[:level].eql?(:log_only) and not Ruport::Config.paranoid?
    Ruport::Config::logger.send(options[:status],message) if Config.logger
    if options[:status].eql? :fatal
      raise(options[:exception] || RuntimeError, message) 
    end
  end
 
  #Alias for Ruport.log
  def self.complain(*args); Ruport.log(*args) end
 
  # yields a Ruport::Config object, allowing you to specify configuration
  # options.
  #
  # Example: 
  #
  #   Ruport.configure do |c|
  #     c.source :default, :dsn => "dbi:mysql:foo",
  #                        :user => "clyde", :password => "pman"
  #   end
  def self.configure(&block)
    block.call(Ruport::Config)
  end
end


%w[config meta_tools report format query data mailer].each { |lib|
  require "ruport/#{lib}" 
}
