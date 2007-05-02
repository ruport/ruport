# ruport.rb : Ruby Reports top level module
#
# Author: Gregory T. Brown (gregory.t.brown at gmail dot com)
#
# Copyright (c) 2006, All Rights Reserved.
#
# This is free software.  You may modify and redistribute this freely under
# your choice of the GNU General Public License or the Ruby License. 
#
# See LICENSE and COPYING for details
#

module Ruport #:nodoc:#
  
  VERSION = "0.11.0"   
  
  class FormatterError < RuntimeError #:nodoc:
  end
  
  # SystemExtensions lovingly ganked from HighLine 1.2.1
  #
  # The following modifications have been made by Gregory Brown on 2006.06.25
  #
  # - Outer Module is changed from HighLine to Ruport
  # - terminal_width / terminal_height added
  #
  # The following modifications have been made by Gregory Brown on 2006.08.13
  # - removed most methods, preserving only terminal geometry features
  #
  # All modifications are under the distributions terms of Ruport.
  # Copyright 2006, Gregory Brown.  All Rights Reserved
  #
  # Original copyright notice preserved below. 
  # --------------------------------------------------------------------------
  #
  #  Created by James Edward Gray II on 2006-06-14.
  #  Copyright 2006 Gray Productions. All rights reserved.
  #
  #  This is Free Software.  See LICENSE and COPYING for details.

  module SystemExtensions #:nodoc:
    module_function
    
    # This section builds character reading and terminal size functions
    # to suit the proper platform we're running on.  Be warned:  Here be
    # dragons!
    #
    begin
      require "Win32API"       # See if we're on Windows.

      # A Windows savvy method to fetch the console columns, and rows.
      def terminal_size
        m_GetStdHandle               = Win32API.new( 'kernel32',
                                                     'GetStdHandle',
                                                     ['L'],
                                                     'L' )
        m_GetConsoleScreenBufferInfo = Win32API.new(
          'kernel32', 'GetConsoleScreenBufferInfo', ['L', 'P'], 'L'
        )

        format        = 'SSSSSssssSS'
        buf           = ([0] * format.size).pack(format)
        stdout_handle = m_GetStdHandle.call(0xFFFFFFF5)
        
        m_GetConsoleScreenBufferInfo.call(stdout_handle, buf)
        bufx, bufy, curx, cury, wattr,
        left, top, right, bottom, maxx, maxy = buf.unpack(format)
        return right - left + 1, bottom - top + 1
      end
    rescue LoadError             # If we're not on Windows try...
      # A Unix savvy method to fetch the console columns, and rows.
      def terminal_size
        size = `stty size 2>/dev/null`.split.map { |x| x.to_i }.reverse
        return $? == 0 ? size : [80,24]
      end

   end
   
   def terminal_width
     terminal_size.first
   end

  end


end

module Kernel
  
  # quiets warnings for block
  def quiet #:nodoc:
    warnings = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = warnings
    return result
  end

end

require "enumerator"
require "ruport/renderer" 
require "ruport/data" 
require "ruport/formatter" 
require "ruport/query" 

if Object.const_defined? :ActiveRecord
  require "ruport/acts_as_reportable"
end
