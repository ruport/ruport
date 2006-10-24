module Ruport::Data
  module Groupable

    def group_by_tag
      r_tags = data.map {|row| row.tags}.flatten.uniq
      d = r_tags.map do |t| 
	      select {|row| row.tags.include? t }.to_table(column_names)      
      end
      r = Record.new d, :attributes => r_tags
      class << r
        def each_group; attributes.each { |a| yield(a) }; end
      end; r
    end

    def create_tag_group(label,&block)
      select(&block).each { |r| r.tag label }
    end

  end
end
