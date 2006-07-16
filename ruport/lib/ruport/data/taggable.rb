module Ruport::Data
  
  module Taggable

    def tag(tag_name)
      tags << tag_name unless has_tag? tag_name
    end

    def delete_tag(tag_name)
      tags.delete tag_name
    end
  
    def has_tag?(tag_name)
      tags.include? tag_name
    end
  
    def tags
      @ruport_tags ||= []
    end
    
    def tags=(tags_list)
      @ruport_tags = tags_list
    end

    def self.extended(obj)
      obj.tags = []
    end
  end
  
end
