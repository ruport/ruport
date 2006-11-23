module Ruport::Data

  #
  # === Overview
  #
  # This module provides a simple mechanism for grouping objects based on 
  # tags.
  #
  module Groupable

    #
    # Creates a <tt>Record</tt> made up of <tt>Table</tt>s containing all the
    # records in the original table with the same tag. 
    #
    # Example:
    #   table = [['inky',  1], 
    #            ['blinky',2], 
    #            ['pinky', 3],
    #            ['clyde', 4]].to_table(['name','score'])
    #
    #   table[0].tag(:winners)
    #   table[1].tag(:losers)
    #   table[2].tag(:winners)
    #   table[3].tag(:losers)
    #
    #   r = table.group_by_tag
    #   puts r[:winners]
    #   => +---------------+
    #      | name  | score |
    #      +---------------+
    #      | inky  |   1   |
    #      | pinky |   3   |
    #      +---------------+
    #
    #   puts r[:losers]  
    #   => +----------------+
    #      |  name  | score |
    #      +----------------+
    #      | blinky |   2   |
    #      | clyde  |   4   |
    #      +----------------+
    #
    def group_by_tag
      r_tags = map { |r| r.tags }.flatten.uniq
      tables_hash = Hash.new { |h,k| h[k] = [].to_table(column_names) }
      each { |row|
        row.tags.each { |t| 
          tables_hash[t].instance_variable_get(:@data) << row
        }
      }
      r = Record.new tables_hash, :attributes => r_tags
      class << r
        def each_group; attributes.each { |a| yield(a) }; end
      end; r
    end

    #
    # Tags each row of the <tt>Table</tt> for which the <tt>block</tt> is not 
    # false with <tt>label</tt>.
    # 
    # Example:
    #   table = [['inky',  1], 
    #            ['blinky',2], 
    #            ['pinky', 3]].to_table(['name','score'])
    #   
    #   table.create_tag_group(:cool_kids) {|r| r.score > 1}
    #   groups = table.group_by_tag(:cool_kids)
    #   
    #   puts group[:cool_kids]
    #   => +----------------+
    #      |  name  | score |
    #      +----------------+
    #      | blinky |   2   |
    #      | pinky  |   3   |
    #      +----------------+
    #
    def create_tag_group(label,&block)
      each { |r| block[r] && r.tag(label) }
      #select(&block).each { |r| r.tag label }
    end
    alias_method :tag_group, :create_tag_group

  end
end
