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
    #   r = table.groups
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
    def groups
      r_tags = group_names_intern
      tables_hash = Hash.new { |h,k| h[k] = Table(column_names) }
      r_tags.each { |t| 
        tables_hash[t.gsub(/^grp_/,"")] = sub_table { |r| r.tags.include? t }}
      r = Record.new tables_hash, :attributes => group_names
    end  
   
    # Gets the names of the groups
    def group_names
       group_names_intern.map { |r| r.gsub(/^grp_/,"") }
    end
    
    # Gets a subtable of the rows matching the group name
    #
    def group(tag)
      sub_table { |r| r.tags.include?("grp_#{tag}") }
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
    #   groups = table.groups
    #   
    #   puts group[:cool_kids]
    #   => +----------------+
    #      |  name  | score |
    #      +----------------+
    #      | blinky |   2   |
    #      | pinky  |   3   |
    #      +----------------+
    #
    def create_group(label,&block)
      each { |r| block[r] && r.tag("grp_#{label}") }
    end  
    
    private
    
    def group_names_intern
       map { |r| r.tags.select { |r| r =~ /^grp_/  } }.flatten.uniq   
    end    

  end
end
