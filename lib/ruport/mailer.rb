# mailer.rb
#  Created by Gregory Brown on 2005-08-16
#  Copyright 2005 (Gregory Brown) All Rights Reserved.
#  This product is free software, you may distribute it as such
#  under your choice of the Ruby license or the GNU GPL
#  See LICENSE for details
require "net/smtp"
require "forwardable"
module Ruport  

    # This class uses SMTP to provide a simple mail sending mechanism.
    # It also uses MailFactory to provide attachment and HTML email support. 
    #
    # Here is a simple example of a message which attaches a readme file:
    #
    #   require "ruport"
    #     
    #   Ruport.configure do |conf| 
    #     conf.mailer :default, 
    #       :host => "mail.adelphia.net", :address => "gregory.t.brown@gmail.com"
    #   end
    #
    #   mailer = Ruport::Mailer.new
    #
    #   mailer.attach "README"
    #
    #   mailer.deliver :to      => "gregory.t.brown@gmail.com",
    #                  :from    => "gregory.t.brown@gmail.com",
    #                  :subject => "Hey there",               
    #                  :text    => "This is what you asked for"
  class Mailer
    extend Forwardable
   
    
    # Creates a new Mailer object.  Optionally, can select a mailer specified
    # by Ruport::Config.
    #
    #   a = Mailer.new # uses the :default mailer
    #   a = Mailer.new :foo # uses :foo mail config from Ruport::Config
    #
    def initialize( mailer_label=:default )
      select_mailer(mailer_label); 
      mail_object.from = @mailer.address if mail_object.from.to_s.empty?
      rescue
        raise "you need to specify a mailer to use"
    end
   
    def_delegators( :@mail, :to, :to=, :from, :from=, 
                           :subject, :subject=, :attach, 
                           :text, :text=, :html, :html= )
   
    # sends the message
    #
    #   mailer.deliver :from => "gregory.t.brown@gmail.com",
    #                  :to   => "greg7224@gmail.com"
    def deliver(options={})
      options.each { |k,v| send("#{k}=",v) if respond_to? "#{k}=" }
      
      Net::SMTP.start(@host,@port,@host,@user,@password,@auth) do |smtp|
        smtp.send_message((options[:mail_object] || mail_object).to_s, options[:from], options[:to] )
      end
    end

    private

    def select_mailer(label)
      @mailer      = Ruport::Config.mailers[label]
      @host       = @mailer.host
      @user       = @mailer.user
      @password   = @mailer.password
      @address    = @mailer.address
      @port       = @mailer.port       || 25
      @auth       = @mailer.auth_type  || :plain
      @mail_klass = @mailer.mail_klass
    end

    def mail_object
      return @mail if @mail
      return @mail ||= @mail_klass.new if @mail_klass
      require "mailfactory"
      @mail ||= MailFactory.new
    end
    
  end
end
