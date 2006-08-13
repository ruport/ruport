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
  # This class serves as the configuration system for Ruport.
  # It's functionality is implemented through Config::method_missing
  #  
  # source :default and mailer :default will become the fallback values if one
  # is not specified in Report::Mailer or Query, but you may define as many
  # sources as you like and switch between them later.
  #
  # An example config file is shown below:
  #   
  #   # password is optional, dsn may omit hostname for localhost
  #   Ruport::Config.source :default,
  #   :dsn => "dbi:mysql:somedb:db.blixy.org",
  #   :user => "root", :password => "chunky_bacon"
  #   
  #   # :password, :port, and :auth_type are optional. :port defaults to 25 and
  #   # :auth_type defaults to :plain.  For more information, see the source
  #   # of Report::Mailer#select_mailer
  #   Ruport::Config.mailer :default,
  #   :host => "mail.chunkybacon.org", :address => "chunky@bacon.net",
  #   :user => "cartoon", :password => "fox", :port => 25, :auth_type => :login
  #   
  #   # optional, if specifed, Ruport#complain will report to it
  #   Ruport::Config.log_file 'foo.log'
  #
  #   # optional, if enabled, will force :log_only complaint calls to
  #   # print to secondary output ($sterr by default).
  #   # call Ruport::Config.disable_paranoia to disable
  #   Ruport::Config.enable_paranoia
  #
  # Alternatively, this configuration could be done by opening the class:
  #   class Ruport::Config
  #
  #     source :default, :dsn => "dbi:mysql:some_db", :user => "root"
  #     
  #     mailer :default, :host => "mail.iheartwhy.com", 
  #     :address => "sandal@ruby-harmonix.net", :user => "sandal",
  #     :password => "abc123"
  #     
  #     logfile 'foo.log'
  #
  #   end
  #
  # Saving this config information into a file and then requiring it can allow
  # you share configurations between Ruport applications.
  #
  module Config
    module_function


    # create or retrieve a database source configuration.
    #
    # setting a source
    #
    #   source :default, :user => "root", :password => "clyde",
    #                    :dsn  => "dbi:mysql:blinkybase"
    #
    # retrieving a source
    #
    #   db = source(:default) #=> <OpenStruct ..>
    #   db.dsn #=> "dbi:mysql:blinkybase"
    def source(*args) 
      return sources[args.first] if args.length == 1
      sources[args.first] = OpenStruct.new(*args[1..-1])
      check_source(sources[args.first],args.first)
    end

    # create or retrieve a mailer configuration
    #
    # creating a mailer config
    #
    #   mailer :alternate, :host => "mail.test.com", 
    #                      :address => "test@test.com",
    #                      :user => "test", :password => "blinky"
    #                      :auth_type => :cram_md5
    #
    # retreiving a mailer config
    #
    #   mail_conf = mailer(:alternate) #=> <OpenStruct ..>
    #   mail_conf.address #=> test@test.com
    def mailer(*args)
      return mailers[args.first] if args.length == 1
      mailers[args.first] = OpenStruct.new(*args[1..-1])
      check_mailer(mailers[args.first],args.first)
    end


    # Sets the logger to use the specified file.
    #
    #   log_file "foo.log"
    def log_file(file)
      @logger = Logger.new(file)
    end
    
    # Same as Config.log_file, but accessor style
    def log_file=(file)
      log_file(file)
    end

    # Returns the source which is labeled :default
    def default_source
      sources[:default]
    end

    # Returns the mailer which is labeled :default
    def default_mailer
      mailers[:default]
    end

    # Returns an array of database source configs
    def sources; @sources ||= {}; end

    # Returns an array of mailer configs
    def mailers; @mailers ||= {}; end

    # Returns the currently active logger
    def logger; @logger; end

    # Forces all messages marked :log_only to surface
    def enable_paranoia; @paranoid = true; end

    # Disables the printing of :log_only messages to STDERR
    def disable_paranoia; @paranoid = false; end

    # Sets paranoid status
    def paranoid=(val); @paranoid = val; end

    # Checks to see if paranoia is enabled
    def paranoid?; !!@paranoid; end
    
    # Verifies that you have provided a DSN for your source
    def check_source(settings,label)
      unless settings.dsn
        Ruport.complain( 
          "Missing DSN for source #{label}!",
          :status => :fatal, :level => :log_only,
          :exception => ArgumentError 
        )
      end
    end

    # Verifies that you have provided a host for your mailer
    def check_mailer(settings, label)
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
