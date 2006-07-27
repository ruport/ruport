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
    
    def source(*args)
      return sources[args.first] if args.length == 1
      sources[args.first] = OpenStruct.new(*args[1..-1])
      check_source(sources[args.first],args.first)
    end

    def mailer(*args)
      mailers[args.first] = OpenStruct.new(*args[1..-1])
      check_mailer(mailers[args.first],args.first)
    end

    def log_file(file)
      @logger = Logger.new(file)
    end
    
    #alias_method :log_file=, :log_file
    def log_file=(file)
      log_file(file)
    end

    def default_source
      sources[:default]
    end

    def default_mailer
      mailers[:default]
    end

    def sources; @sources ||= {}; end

    def mailers; @mailers ||= {}; end

    def logger; @logger; end

    def enable_paranoia; @paranoid = true; end
    def disable_paranoia; @paranoid = false; end
    def paranoid=(val); @paranoid = val; end
    def paranoid?; !!@paranoid; end
    
    def check_source(settings,label)
      unless settings.dsn
        Ruport.complain( 
          "Missing DSN for source #{label}!",
          :status => :fatal, :level => :log_only,
          :exception => ArgumentError 
        )
      end
    end

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
