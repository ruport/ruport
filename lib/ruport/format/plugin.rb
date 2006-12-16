# format/plugin.rb : Generalized formatting plugin base class for Ruby Reports
#
# Created by Gregory Brown.  Copyright December 2006, All Rights Reserved.
#
# This is free software, please see LICENSE and COPYING for details.

module Ruport
  module Format
    class Plugin

      attr_accessor :layout
      attr_accessor :data

      # Stores a string used for outputting formatted data.
      def output
        @output ||= ""
      end

      # Provides a generic OpenStruct for storing plugin options
      def options
        @options ||= OpenStruct.new
      end 

      # clears output.  Useful if you are building your own interface to
      # plugins.
      def clear_output
        @output.replace("")
      end
    end
  end
end
