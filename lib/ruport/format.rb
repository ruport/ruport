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

  # Ruport makes heavy use of ruby's advanced meta programming features in 
  # this Class.
  #
  # All subclasses of Ruport::Format::Engine and Ruport::Format::Plugin
  # (both Ruports' internal ones and any custom ones outside the Ruport 
  # library) should dynamically register themselves with this class.
  #
  # All report generation is then done via Format, not with the engines
  # and plugins directly.
  #
  # For each engine that is registered with Format, 2 methods are created:
  #  - <enginename>; and
  #  - <enginename>_object
  #
  # Either one of these methods can be used to create your report, depending
  # on your requirments.
  #
  # = Format.enginename
  #
  # A brief example of creating a simple report with the table engine
  #   
  #   data = [[1,2],[5,3],[3,10]].to_table(%w[a b])
  #   File.open("myreport.pdf","w") { |f| f.puts Ruport::Format.table(:plugin => :pdf, :data => data)}
  #
  # = Format.enginename_object
  # 
  # A slightly different way to create a simple report with the table engine. 
  # This technique gives you a chance to modify some of the engines settings
  # before calling render manually.
  #
  #   data = [[1,2],[5,3],[3,10]].to_table(%w[a b])
  #   myreport = Ruport::Format.table_object :plugin => :pdf, :data => data
  #   File.open("myreport.pdf","w") { |f| f.puts myreport.render }
  # 
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

    %w[renderer engine plugin].each { |lib|
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
        

        options[:data] = options[:data].dup if options[:data]
        
        options.each do |k,v|
          my_engine.send("#{k}=",v) if my_engine.respond_to? k
        end
        
        options[:auto_render] ? my_engine.render : my_engine.dup
      end


    
  end
end

