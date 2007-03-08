# format/plugin.rb : Generalized formatting plugin base class for Ruby Reports
#
# Created by Gregory Brown.  Copyright December 2006, All Rights Reserved.
#
# This is free software, please see LICENSE and COPYING for details.

module Ruport
  module Format
    
    module RenderingTools

      def render_data_by_row(options={},&block)
        data.each do |r|
          render_row(r,options,&block)
        end
      end

      def render_row(row,options={},&block)
        options = {:data => row, :io => output}.merge(options)
        Renderer::Row.render(format,options) do |rend|
          block[rend] if block
        end
      end

      def render_table(table,options={},&block)
        options = {:data => table, :io => output}.merge(options)
        Renderer::Table.render(format,options) do |rend|
          block[rend] if block
        end
      end

      def render_group(group,options={},&block)
        options = {:data => group, :io => output}.merge(options)
        Renderer::Group.render(format,options) do |rend|
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

    class Plugin

      include RenderingTools
      include OptionAccessors

      attr_accessor :options
      attr_accessor :data
      attr_accessor :format

      def self.renders(format,options={})
        options[:for].add_format(self,format)
        formats << format unless formats.include?(format)
      end
      
      def self.formats
        @formats ||= []
      end

      # Stores a string used for outputting formatted data.
      def output
        return options.io if options.io
        @output ||= ""
      end

      # Provides a generic OpenStruct for storing plugin options
      def options
        @options ||= Renderer::Options.new
      end 

      # clears output.  Useful if you are building your own interface to
      # plugins.
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
end
