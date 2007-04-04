# formatter.rb : Generalized formatting base class for Ruby Reports
#
# Created by Gregory Brown.  Copyright December 2006, All Rights Reserved.
#
# This is free software, please see LICENSE and COPYING for details.

module Ruport
  class Formatter
    
    module RenderingTools

      # Iterates through <tt>data</tt> and passes
      # each row to render_row with the given options
      def render_data_by_row(options={},&block)
        data.each do |r|
          render_row(r,options,&block)
        end
      end

      # Uses Renderer::Row to render the Row object with the
      # given options.
      #
      # Sets the :io attribute by default to the existing formatter's
      # output object.
      def render_row(row,options={},&block)
        render_helper(Renderer::Row,row,options,&block)
      end

      # Uses Renderer::Table to render the Table object with the
      # given options.
      #
      # Sets the :io attribute by default to the existing formatter's
      # output object.
      def render_table(table,options={},&block)
        render_helper(Renderer::Table,table,options,&block)
      end

      # Uses Renderer::Group to render the Group object with the
      # given options.
      #
      # Sets the :io attribute by default to the existing formatter's
      # output object.
      def render_group(group,options={},&block)
        render_helper(Renderer::Group,group,options,&block)
      end

      # Uses Renderer::Grouping to render the Grouping object with the
      # given options.
      #
      # Sets the :io attribute by default to the existing formatter's
      # output object.
      def render_grouping(group,options={},&block)
        render_helper(Renderer::Grouping,group,options,&block)
      end 

      private

      def render_helper(rend_klass, source_data,options={},&block)
        options = {:data => source_data, :io => output}.merge(options)
        rend_klass.render(format,options) do |rend|
          block[rend] if block
        end
      end

    end

    include RenderingTools

    attr_accessor :options
    attr_accessor :data
    attr_accessor :format

    # Registers the formatter with one or more Renderers
    #
    #   renders :pdf, :for => MyRenderer
    #   renders [:csv,:html], :for => YourRenderer
    #   render :text, :for => [MyRenderer,YourRenderer]
    #
    def self.renders(fmts,options={})
      Array(fmts).each do |format|
        Array(options[:for]).each do |o| 
          o.send(:add_format,self,format) 
          formats << format unless formats.include?(format)
        end    
      end
    end   
    
    # allows the options specified to be accessed directly
    # 
    #   opt_reader :something
    #   something == options.something #=> true
    def self.opt_reader(*opts) 
      require "forwardable"
      extend Forwardable
      opts.each { |o| def_delegator :@options, o }
    end
    
    # Gives a list of formats registered for this plugin.
    # (but not which renderers they're registered on)
    def self.formats
      @formats ||= []
    end

    # Stores a string used for outputting formatted data.
    def output
      return options.io if options.io
      @output ||= ""
    end

    # Provides a generic OpenStruct for storing formatter options
    def options
      @options ||= Renderer::Options.new
    end 

    # clears output.  Useful if you are building your own interface to
    # formatters.
    def clear_output
      @output.replace("")
    end

    # Provides a shortcut for per format handlers.
    #
    # Example:
    #
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

require "ruport/formatter/csv"
require "ruport/formatter/html"
require "ruport/formatter/text"
require "ruport/formatter/pdf"
