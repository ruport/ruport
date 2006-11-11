# ruport/config.rb : Ruby Reports configuration system
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
require "ostruct"
module Ruport
  #
  # This class serves as the configuration system for Ruport.
  #  
  # The source and mailer defined as <tt>:default</tt> will become the 
  # fallback values if you don't specify one in <tt>Report::Mailer</tt> or 
  # <tt>Query</tt>, but you may define as many sources as you like and switch 
  # between them later.
  #
  # The most common way to access your application configuration is through 
  # the <tt>Ruport.configure</tt> method, like this:
  #   
  #   Ruport.configure do |config|
  #
  #     config.log_file 'foo.log'
  #     config.enable_paranoia
  #
  #     config.source :default,
  #                   :dsn => "dbi:mysql:somedb:db.blixy.org",
  #                   :user => "root", 
  #                   :password => "chunky_bacon"
  #   
  #     config.mailer :default,
  #                   :host => "mail.chunkybacon.org", 
  #                   :address => "chunky@bacon.net",
  #                   :user => "cartoon", 
  #                   :password => "fox", 
  #                   :port => 25, 
  #                   :auth_type => :login
  #
  #   end
  #
  # You can accomplish the same thing by opening the class directly:
  #
  #   class Ruport::Config
  #
  #     source :default, 
  #            :dsn => "dbi:mysql:some_db", 
  #            :user => "root"
  #     
  #     mailer :default, 
  #            :host => "mail.iheartwhy.com", 
  #            :address => "sandal@ruby-harmonix.net", 
  #            :user => "sandal",
  #            :password => "abc123"
  #     
  #     logfile 'foo.log'
  #
  #   end
  #
  # Saving this config information into a file and then requiring it allows
  # you to share configurations between Ruport applications. 
  #
  module Config
    module_function
    # 
    # :call-seq:
    #   source(source_name, options)
    #
    # Creates or retrieves a database source configuration. Available options
    # are:
    # <b><tt>:user</tt></b>::       The user used to connect to the database.
    # <b><tt>:password</tt></b>::   The password to use to connect to the 
    #                               database (optional).
    # <b><tt>:dsn</tt></b>::        The dsn string that dbi will use to 
    #                               access the database.
    #
    # Example (setting a source): 
    #   source :default, :user => "root", 
    #                    :password => "clyde",
    #                    :dsn  => "dbi:mysql:blinkybase"
    #
    # Example (retrieving a source):
    #   db = source(:default) #=> <OpenStruct ..>
    #   db.dsn                #=> "dbi:mysql:blinkybase"
    #
    def source(*args) 
      return sources[args.first] if args.length == 1
      sources[args.first] = OpenStruct.new(*args[1..-1])
      check_source(sources[args.first],args.first)
    end

    # 
    # :call-seq:
    #   mailer(mailer_name, options)
    #
    # Creates or retrieves a mailer configuration. Available options:
    # <b><tt>:host</tt></b>::         The SMTP host to use.
    # <b><tt>:address</tt></b>::      The email address to send to.
    # <b><tt>:user</tt></b>::         The username to use on the SMTP server
    # <b><tt>:password</tt></b>::     The password to use on the SMTP server. 
    #                                 Optional.
    # <b><tt>:port</tt></b>::         The SMTP port to use. Optional, defaults
    #                                 to 25.
    # <b><tt>:auth_type</tt></b>::    SMTP authorization method. Optional, 
    #                                 defaults to <tt>:plain</tt>.
    # <b><tt>:mail_klass</tt></b>::   If you don't want to use the default 
    #                                 <tt>MailFactory</tt> object, you can 
    #                                 pass another mailer to use here.
    #                               
    # Example (creating a mailer config):
    #   mailer :alternate, :host => "mail.test.com", 
    #                      :address => "test@test.com",
    #                      :user => "test", 
    #                      :password => "blinky"
    #                      :auth_type => :cram_md5
    #
    # Example (retreiving a mailer config):
    #   mail_conf = mailer(:alternate)  #=> <OpenStruct ..>
    #   mail_conf.address               #=> test@test.com
    #
    def mailer(*args)
      return mailers[args.first] if args.length == 1
      mailers[args.first] = OpenStruct.new(*args[1..-1])
      check_mailer(mailers[args.first],args.first)
    end

    # The file that <tt>Ruport.log()</tt> will write to.
    def log_file(file)
      @logger = Logger.new(file)
    end
    
    # Same as <tt>Config.log_file</tt>, but accessor style.
    def log_file=(file)
      log_file(file)
    end

    # Alias for <tt>sources[:default]</tt>.
    def default_source
      sources[:default]
    end

    # Alias for <tt>mailers[:default]</tt>.
    def default_mailer
      mailers[:default]
    end

    # Returns all <tt>source</tt>s defined in this <tt>Config</tt>.
    def sources; @sources ||= {}; end

    # Returns all the <tt>mailer</tt>s defined in this <tt>Config</tt>.
    def mailers; @mailers ||= {}; end

    # Returns the currently active logger.
    def logger; @logger; end

    # Forces all messages marked <tt>:log_only</tt> to print anyway.
    def enable_paranoia; @paranoid = true; end

    # Disables the printing of <tt>:log_only</tt> messages.
    def disable_paranoia; @paranoid = false; end

    # Sets paranoid status.
    def paranoid=(val); @paranoid = val; end

    # Checks to see if paranoia is enabled.
    def paranoid?; !!@paranoid; end
    
    # Verifies that you have provided a DSN for your source.
    def check_source(settings,label) # :nodoc:
      unless settings.dsn
        Ruport.complain( 
          "Missing DSN for source #{label}!",
          :status => :fatal, :level => :log_only,
          :exception => ArgumentError 
        )
      end
    end

    # Verifies that you have provided a host for your mailer.
    def check_mailer(settings, label) # :nodoc:
      unless settings.host
        Ruport.complain(
          "Missing host for mailer #{label}",
          :status => :fatal, :level => :log_only,
          :exception => ArgumentError
        )
      end
    end
    
  end
end
