require 'rubygems'
require 'mechanize'
require 'ruport'

version = Ruport::VERSION =~ /(\d+.\d+.\d+)/ && $1

FOCUS = { :minor_bugs => 6, :major_bugs => 7, :minor_features => 4,
          :major_features => 5, :cleanup => 3, :documentation => 2 }

agent = WWW::Mechanize.new #{|a| a.log = Logger.new(STDERR) }
page = agent.get("http://rubyforge.org/projects/ruport")
download = page.links.text(/Download/).first
release = download.uri.to_s[-15..-1]
agent.get(download.uri)

links = agent.page.links

links_hash = %w[zip tar.gz tar.bz2].inject({}) {|h,ext| 
  h.merge(ext => "http://rubyforge.org"+links.text(/#{ext}/).first.uri.to_s)
}

agent.get("http://freshmeat.net/login/")
form = agent.page.forms[2]
form.field("username").value = "anonymouse"
form.field("password").value = ARGV[0]
agent.submit(form, form.buttons.first)
agent.get("http://freshmeat.net/projects/ruport/")
link = agent.page.links.text(/add release/).first
agent.click link


form = agent.page.forms[2]

s = form.field("add_release[release_focus_name]")
s.value = s.options[5].value

t = form.field("add_release[hide_from_frontpage]")
t.value = t.options[0].value

form.field("add_release[version]").value = version
form.field("add_release[changes]").value = File.read("notes")

form.field("add_release[url_tgz]").value = links_hash["tar.gz"]
form.field("add_release[url_bz2]").value = links_hash["tar.bz2"]
form.field("add_release[url_zip]").value = links_hash["zip"]
form.field("add_release[url_changelog]").value = "http://rubyforge.org/frs/shownotes.php?#{release}"

agent.submit(form,form.buttons[0])


form = agent.page.forms[2]
agent.submit(form,form.buttons[0])
