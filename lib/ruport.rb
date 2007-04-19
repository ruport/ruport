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
  
  VERSION = "0.9.6"
  
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
  # <b><tt>:raises</tt></b>::    The +Exception+ to throw on failure.  This 
  #                              defaults to +RuntimeError+.
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


  # SystemExtensions
  # lovingly ganked from HighLine 1.2.1
  #
  # The following modifications have been made by Gregory Brown on 2006.06.25
  #
  # - Outer Module is changed from HighLine to Ruport
  # - terminal_width / terminal_height added
  #
  # The following modifications have been made by Gregory Brown on 2006.08.13
  # - removed most methods, preserving only terminal geometry features
  #
  # All modifications are under the distributions terms of Ruport.
  # Copyright 2006, Gregory Brown.  All Rights Reserved
  #
  # Original copyright notice preserved below. 
  # --------------------------------------------------------------------------
  #
  #  Created by James Edward Gray II on 2006-06-14.
  #  Copyright 2006 Gray Productions. All rights reserved.
  #
  #  This is Free Software.  See LICENSE and COPYING for details.

  module SystemExtensions #:nodoc:
    module_function
    
    #
    # This section builds character reading and terminal size functions
    # to suit the proper platform we're running on.  Be warned:  Here be
    # dragons!
    #
    begin
      require "Win32API"       # See if we're on Windows.

      # A Windows savvy method to fetch the console columns, and rows.
      def terminal_size
        m_GetStdHandle               = Win32API.new( 'kernel32',
                                                     'GetStdHandle',
                                                     ['L'],
                                                     'L' )
        m_GetConsoleScreenBufferInfo = Win32API.new(
          'kernel32', 'GetConsoleScreenBufferInfo', ['L', 'P'], 'L'
        )

        format        = 'SSSSSssssSS'
        buf           = ([0] * format.size).pack(format)
        stdout_handle = m_GetStdHandle.call(0xFFFFFFF5)
        
        m_GetConsoleScreenBufferInfo.call(stdout_handle, buf)
        bufx, bufy, curx, cury, wattr,
        left, top, right, bottom, maxx, maxy = buf.unpack(format)
        return right - left + 1, bottom - top + 1
      end
    rescue LoadError             # If we're not on Windows try...
      # A Unix savvy method to fetch the console columns, and rows.
      def terminal_size
        size = `stty size 2>/dev/null`.split.map { |x| x.to_i }.reverse
        return $? == 0 ? size : [80,24]
      end

   end
   
   def terminal_width
     terminal_size.first
   end

  end

  require 'timeout'

  class Attempt # :nodoc:
    VERSION = '0.1.0'

    # Number of attempts to make before failing.  The default is 3.
    attr_accessor :tries

    # Number of seconds to wait between attempts.  The default is 60.
    attr_accessor :interval

    # a level which ruport understands.  
    attr_accessor :log_level

    # If set, this increments the interval with each failed attempt by that
    # number of seconds.
    attr_accessor :increment

    # If set, the code block is further wrapped in a timeout block.
    attr_accessor :timeout

    # Determines which exception level to check when looking for errors to
    # retry.  The default is 'Exception' (i.e. all errors).
    attr_accessor :level

    # :call-seq:
    #    Attempt.new{ |a| ... }
    # 
    # Creates and returns a new +Attempt+ object.  Use a block to set the
    # accessors.
    # 
    def initialize           
      @tries     = 3         # Reasonable default
      @interval  = 60        # Reasonable default
      @increment = nil       # Should be an int, if provided
      @timeout   = nil       # Wrap the code in a timeout block if provided
      @level     = Exception # Level of exception to be caught
      
      yield self if block_given?
    end

    def attempt
      count = 1
      begin
         if @timeout
            Timeout.timeout(@timeout){ yield }
         else
            yield
         end
      rescue @level => error
         @tries -= 1
         if @tries > 0
            msg = "Error on attempt # #{count}: #{error}; retrying"
            count += 1
            Ruport.log(msg, :level => log_level)
            @interval += @increment if @increment
            sleep @interval
            retry
         end
         raise
      end
    end
  end


end

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

require "enumerator"
require "ruport/config"
require "ruport/renderer" 
require "ruport/data" 
require "ruport/report"  
require "ruport/formatter" 
require "ruport/query" 

if Object.const_defined? :ActiveRecord
  require "ruport/acts_as_reportable"
end
