#--
# sqlsplit.rb : A tool to properly split SQL input
#
# This is Free Software.  You may freely redistribute or modify under the terms
# of the GNU General Public License or the Ruby License.  See LICENSE and
# COPYING for details.
#
# Created by Francis Hwang, 2005.12.31
# Copyright (c) 2005, All Rights Reserved.
#++
module Ruport
  class Query
    # This class properly splits up multi-statement SQL input for use with
    # Ruby/DBI
    class SqlSplit < Array
			def initialize( sql )
				super()
				next_sql = ''
				sql.each do |line|
					unless line =~ /^--/ or line =~ %r{^/\*.*\*/;} or line =~ /^\s*$/
						next_sql << line
						if line =~ /;$/
							next_sql.gsub!( /;\s$/, '' )
							self << next_sql
							next_sql = ''
						end
					end
				end
				self << next_sql if next_sql != ''
			end
		end
  end
end
