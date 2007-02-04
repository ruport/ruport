begin
  require "rubygems"
  gem "ruport","=0.8.0"
rescue LoadError 
  nil
end
require "ruport"
require "lib/helpers"
require "config/ruport_config"
