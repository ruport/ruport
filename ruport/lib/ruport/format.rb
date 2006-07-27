# format.rb : Ruby Reports formatting module
#
# Author: Gregory T. Brown (gregory.t.brown at gmail dot com)
#
# Copyright (c) 2006, All Rights Reserved.
#
# This is free software.  You may modify and redistribute this freely under
# your choice of the GNU General Public License or the Ruby License. 
#
# See LICENSE and COPYING for details
module Ruport
  
  
# Ruport's Format model is meant to help get your data in a suitable format for
# output.  Rather than make too many assumptions about how you will want your
# data to look, a number of tools have been built so that you can quickly define
# those things yourself.
#
# There are three main sets of functionality the Ruport::Format model provides.
#   * Structured printable document support ( Format::Document and friends)
#   * Text filter support ( Report#render and the Format class)
#   * Support for DataSet Formatting ( Format::Builder)
#
# The support for structured printable documents is currently geared towards PDF
# support and needs some additional work to be truly useful.  Suggestions would
# be much appreciated.
#
# Format::Builder lets you define functions that will be used via DataSet#as
# This is primary geared towards tabular data output, but there is no reason why
# DataSet#as and the <tt>render_foo</tt> methods of Format::Builder cannot be
# adapted to fit whatever needs you may need.
#
# The filters implemented in the Format class are meant to process strings or
# entire templates.  The Format class will soon automatically build a
# Ruport::Parser for any string input.  By default, filters are provided to
# process erb, pure ruby, and redcloth.  It is trivial to extend this
# functionality though.
#
# This is best shown by a simple example:
#
#   a = Ruport::Report.new
#   Ruport::Format.register_filter :reverser do
#     content.reverse
#   end
#   a.render "somestring", :filters => [:reverser]
#   
#   Output: "gnirtsemos"
#
# Filters can be combined, and you can run them in different orders to obtain
# different results.
#
# See the source for the built in filters for ideas.
#
# Also, see Report#render for how to bind Format objects to your own classes.
#
# When combined, filters, data set output templates, and structured printable
# document facilities create a complete Formatting system.
#
# This part of Ruport is under active development.  Please do feel free to
# submit feature requests or suggestions.
  class Format
    
    # Builds a simple interface to a formatting engine.
    # Two of these interfaces are built into Ruport:
    # Format.document and Format.table
    #
    # These interfaces pass a hash of keywords to the associative engine.  
    # Here is a simple example:
    # 
    # Format.build_interface_for Format::Engine::Table, "table"
    # 
    # This will allow the following code to work:
    # 
    # Format.table :data => [[1,2],[3,4]], :plugin => :csv
    #  
    # So, if you want to create a standard interface to a 
    # custom built engine, you could simply do something like:
    # 
    # Format.build_interface_for MyCustomEngine, "my_name"
    #
    # which would be accessible via
    #
    # Format.my_name ...
    def self.build_interface_for(engine,name)
      singleton_class.send(:define_method, name, 
        lambda { |options| simple_interface(engine, options) })
      singleton_class.send(:define_method, "#{name}_object",
        lambda { |options|
          options[:auto_render] = false; simple_interface(engine,options) })
    end

    %w[open_node document engine plugin].each { |lib|
       require "ruport/format/#{lib}" 
    }

    @@filters = Hash.new
    
    # To hook up a Format object to your current class, you need to pass it a
    # binding.  This way, when filters are being processed, they will be
    # evaluated in the context of the object they are being called from, rather
    # than within an instance of Format.
    #
    def initialize(class_binding=binding)
      @binding = class_binding
    end
    
    # This is the text to be processed by the filters
    attr_accessor :content
    
    # This is the binding to the object Format is tied to
    attr_accessor :binding
    
    # Processes the ERB text in <tt>@content</tt> in the context
    # of the object that Format is bound to.
    def filter_erb  
      self.class.document :data => @content, 
                          :class_binding => @binding,
                          :plugin => :text
    end
    
    # Processes the RedCloth text in <tt>@content</tt> in the context
    # of the object that Format is bound to.
    def filter_red_cloth
      self.class.document :data => @content, :plugin => :html
    end
    
    # Takes a name and a block and creates a filter method
    # This will define methods in the form of 
    # <tt>Format#filter_my_filter_name</tt>.
    #
    # This code will run as an instance method on Format.
    # You can access format and binding through their accessors,
    # as well as any other filters.
    #
    # Example:
    #
    #   Format.register_filter :no_ohz do
    #     content.gsub(/O/i,"")
    #   end
    def self.register_filter(name,&filter_proc)
      @@filters["filter_#{name}".to_sym] = filter_proc 
    end

    def method_missing(m,*args)
      @@filters[m] ? @@filters[m][@content] : super
    end


    private

     def self.simple_interface(engine, options={})
        my_engine = engine.dup
        
        my_engine.send(:plugin=,options[:plugin])
        options = my_engine.active_plugin.rendering_options.merge(options)
       
        options[:auto_render] = true unless options.has_key? :auto_render
        

        options[:data] = options[:data].dup
        
        options.each do |k,v|
          my_engine.send("#{k}=",v) if my_engine.respond_to? k
        end
        
        options[:auto_render] ? my_engine.render : my_engine.dup
      end


    
  end
end

