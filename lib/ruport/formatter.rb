# formatter.rb : Generalized formatting base class for Ruby Reports
#
# Created by Gregory Brown.  Copyright December 2006, All Rights Reserved.
#
# This is free software, please see LICENSE and COPYING for details.

module Ruport
  class Formatter
    
    module RenderingTools

      def render_data_by_row(options={},&block)
        data.each do |r|
          render_row(r,options,&block)
        end
      end

      def render_row(row,options={},&block)
        render_helper(Renderer::Row,row,options,&block)
      end

      def render_table(table,options={},&block)
        render_helper(Renderer::Table,table,options,&block)
      end

      def render_group(group,options={},&block)
        render_helper(Renderer::Group,group,options,&block)
      end

      private

      def render_helper(rend_klass, source_data,options={},&block)
        options = {:data => source_data, :io => output}.merge(options)
        rend_klass.render(format,options) do |rend|
          block[rend] if block
        end
      end

    end

    module OptionAccessors


      module ClassMethods
        def opt_reader(*opts)
          require "forwardable"
          extend Forwardable
          opts.each { |o| def_delegator :@options, o }
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
    end

    include RenderingTools
    include OptionAccessors

    attr_accessor :options
    attr_accessor :data
    attr_accessor :format

    def self.renders(fmts,options={})
      Array(fmts).each do |format|
        Array(options[:for]).each do |o| 
          o.send(:add_format,self,format) 
          formats << format unless formats.include?(format)
        end    
      end
    end
    
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
