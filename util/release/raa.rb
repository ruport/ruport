require "rubygems"
require "ruport"
require "mechanize"
 
(puts "Need password"; exit) unless ARGV[0]

frontpage = 'http://raa.ruby-lang.org/update.rhtml?name=ruport'
agent = WWW::Mechanize.new
page = agent.get frontpage
form = page.forms[1]
form.fields.name("pass").value = ARGV[0]
form.fields.name("version").value = ARGV[1]
page = agent.submit(form, form.buttons[0])
