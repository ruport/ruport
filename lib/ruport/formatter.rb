# Ruport : Extensible Reporting System                                
#
# formatter.rb provides a generalized base class for creating ruport formatters.
#     
# Created By Gregory Brown
# Copyright (C) December 2006, All Rights Reserved.   
#
# This is free software distributed under the same terms as Ruby 1.8
# See LICENSE and COPYING for details.
module Ruport    
  # Formatter is the base class for Ruport's format implementations.
  #
  # Typically, a Formatter will implement one or more output types,
  # and be registered with one or more Controller classes. 
  #
  # This class provides all the necessary base functionality to make
  # use of Ruport's rendering system, including option handling, data
  # access, and basic output wrapping.
  #
  # The following example should provide a general idea of how formatters
  # work, but see the built in formatters for reference implementations. 
  # 
  # A simple Controller definition is included to help show the example in
  # context, but you can also build your own custom interface to formatter
  # if you wish.
  #
  #   class ReverseController < Ruport::Controller
  #      stage :reversed_header, :reversed_body 
  #   end
  #                                            
  #   class ReversedText < Ruport::Formatter 
  #      
  #      # Hooks formatter up to controller
  #      renders :txt, :for => ReverseController      
  #      
  #      # Implements ReverseController's :reversed_header hook
  #      # but can be used by any controller   
  #      def build_reversed_header   
  #         output << "#{options.header_text}\n"
  #         output << "The reversed text will follow\n"
  #      end  
  # 
  #      # Implements ReverseController's :reversed_body hook
  #      # but can be used by any controller
  #      def build_reversed_body
  #         output << data.reverse << "\n"
  #      end         
  #
  #   end    
  #
  #   puts ReverseController.render_txt(:data => "apple",
  #                                   :header_text => "Hello Mike, Hello Joe!")
  #   
  #   -----
  #   OUTPUT: 
  # 
  #   Hello Mike, Hello Joe!
  #   The reversed text will follow
  #   elppa
  #   
  class Formatter
     
    # Provides shortcuts so that you can use Ruport's default rendering
    # capabilities within your custom formatters   
    #
    module RenderingTools
      # Uses Controller::Row to render the Row object with the
      # given options.
      #
      # Sets the <tt>:io</tt> attribute by default to the existing 
      # formatter's <tt>output</tt> object.
      def render_row(row,options={},&block)
        render_helper(Controller::Row,row,options,&block)
      end

      # Uses Controller::Table to render the Table object with the
      # given options.
      #
      # Sets the :io attribute by default to the existing formatter's
      # output object.
      def render_table(table,options={},&block)
        render_helper(Controller::Table,table,options,&block)
      end

      # Uses Controller::Group to render the Group object with the
      # given options.
      #
      # Sets the :io attribute by default to the existing formatter's
      # output object.
      def render_group(group,options={},&block)
        render_helper(Controller::Group,group,options,&block)
      end

      # Uses Controller::Grouping to render the Grouping object with the
      # given options.
      #
      # Sets the :io attribute by default to the existing formatter's
      # output object.
      def render_grouping(grouping,options={},&block)
        render_helper(Controller::Grouping,grouping,options,&block)
      end
      
      # Iterates through the data in the grouping and renders each group
      # followed by a newline.
      #
      def render_inline_grouping(options={},&block)
        data.each do |_,group|                     
          render_group(group, options, &block)
          output << "\n"
        end
      end

      private

      def render_helper(rend_klass, source_data,options={},&block)
        options = {:data => source_data, 
                   :io => output,
                   :layout => false }.merge(options)       
                   
        options[:io] = "" if self.class.kind_of?(Ruport::Formatter::PDF)
        rend_klass.render(format,options) do |rend|
          block[rend] if block
        end
      end

    end

    include RenderingTools
   
    # Set by the <tt>:data</tt> attribute from Controller#render
    attr_reader :data              
    
    # Set automatically by Controller#render(format) or Controller#render_format
    attr_accessor :format                                                    
    
    # Set automatically by Controller#render as a Controller::Options object built
    # by the hash provided.
    attr_writer :options

    # Registers the formatter with one or more Controllers.
    #
    #   renders :pdf, :for => MyController
    #   render :text, :for => [MyController,YourController]
    #   renders [:csv,:html], :for => YourController
    #
    def self.renders(fmts,options={})
      Array(fmts).each do |format|
        Array(options[:for]).each do |o| 
          o.send(:add_format,self,format) 
          formats << format unless formats.include?(format)
        end    
      end
    end
    
    # Allows you to implement stages in your formatter using the
    # following syntax:
    #
    #   class ReversedText < Ruport::Formatter 
    #      renders :txt, :for => ReverseController
    #      
    #      build :reversed_header do
    #         output << "#{options.header_text}\n"
    #         output << "The reversed text will follow\n"
    #      end
    # 
    #      build :reversed_body do
    #         output << data.reverse << "\n"
    #      end
    #   end
    #
    def self.build(stage,&block)
      define_method "build_#{stage}", &block
    end
    
    # Gives a list of formats registered for this formatter.
    def self.formats
      @formats ||= []
    end   
    
    # Returns the template currently set for this formatter.
    def template
      Template[options.template] rescue nil || Template[:default]
    end

    # Stores a string used for outputting formatted data.
    def output
      return options.io if options.io
      @output ||= ""
    end

    # Provides a Controller::Options object for storing formatting options.
    def options
      @options ||= Controller::Options.new
    end 

    # Sets the data object, making a local copy using #dup. This may have
    # a significant overhead for large tables, so formatters which don't
    # modify the data object may wish to override this.
    def data=(val)
      @data = val.dup
    end

    # Clears the output.
    def clear_output
      @output.replace("")
    end
    
    # Saves the output to a file.
    def save_output(filename)
      File.open(filename,"w") {|f| f << output }
    end
    
    # Use to define that your formatter should save in binary format
    def self.save_as_binary_file
      define_method :save_output do |filename|
        File.open(filename,"wb") {|f| f << output }
      end
    end
    
    # Evaluates the string using ERB and returns the results.
    #
    # If <tt>:binding</tt> is specified, it will evaluate the template
    # in that context.
    def erb(string,options={})      
      require "erb"
      if string =~ /(\.r\w+)|(\.erb)$/
        ERB.new(File.read(string)).result(options[:binding]||binding)
      else
        ERB.new(string).result(options[:binding]||binding)
      end
    end

    # Provides a shortcut for per-format handlers.
    #
    # Example:
    #
    #   # will only be called if formatter is called for html output
    #   html { output << "Look, I'm handling html" }
    #
    def method_missing(id,*args)
      if self.class.formats.include?(id)
        yield() if format == id
      else
        super
      end
    end
  end
end                                

require "ruport/formatter/template"
require "ruport/formatter/csv"
require "ruport/formatter/html"
require "ruport/formatter/text"
require "ruport/formatter/pdf"
