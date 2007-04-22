begin
  require "rubygems"
  gem "ruport","=0.9.6"
rescue LoadError 
  nil
end
require "ruport"
require "lib/helpers"
require "config/environment"

class String
  def /(other)
   self + "/" + other
  end
end

class Ruport::Report
  
  def output_dir
    config.output_dir or dir('output')
  end

  def data_dir
    config.data_dir or dir('data')
  end

  def query_dir
    config.query_dir or dir('sql')
  end

  def template_dir
    config.template_dir or dir('templates')
  end

  private
  def dir(name)
    "/Users/mikem836/ruport/itunes/#{name}"
  end
end
