require "ruport"

Ruport.configure do |conf| 
  conf.mailer :default, 
    :host => "mail.adelphia.net", :address => "gregory.t.brown@gmail.com"
end

mailer = Ruport::Mailer.new

mailer.attach "README"

mailer.deliver :to      => "gregory.t.brown@gmail.com",
               :from    => "gregory.t.brown@gmail.com",
               :subject => "Hey there",               
               :text    => "This is what you asked for"
