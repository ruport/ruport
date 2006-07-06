# mailer.rb
#  Created by Gregory Brown on 2005-08-16
#  Copyright 2005 (Gregory Brown) All Rights Reserved.
#  This product is free software, you may distribute it as such
#  under your choice of the Ruby license or the GNU GPL
#  See LICENSE for details
require "net/smtp"
require "forwardable"
module Ruport  
    class Mailer
      extend Forwardable
      
      def initialize( mailer_label=:default )
        select_mailer(mailer_label); 
        mail_object.from = @mailer.address if mail_object.from.to_s.empty?
        rescue
          raise "you need to specify a mailer to use"
      end
     
      def_delegators( :@mail, :to, :to=, :from, :from=, 
                             :subject, :subject=, :attach, 
                             :text, :text=, :html, :html= )
      
      def deliver(options={})
        options.each { |k,v| send("#{k}=",v) if respond_to? "#{k}=" }
        
        Net::SMTP.start(@host,@port,@host,@user,@password,@auth) do |smtp|
          smtp.send_message((options[:mail_object] || mail_object).to_s, options[:from], options[:to] )
        end
      end

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
