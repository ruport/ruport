# The Ruport Data Collections.
# Authors: Gregory Brown / Dudley Flanders
#
# This is Free Software.  For details, see LICENSE and COPYING
# Copyright 2006 by respective content owners, all rights reserved.
module Ruport::Data
  
  # This module provides a simple mechanism for tagging arbitrary objects.  This
  # provides the necessary methods to set and retrieve tags which can consist of
  # any Ruby object.  This is used by Data::Record and the Ruport Data
  # Collections.
  module Taggable

    # Adds a tag to the object 
    #   taggable_obj.tag :spiffy
    def tag(tag_name)
      tags << tag_name unless has_tag? tag_name
    end
    
    # Removes a tag
    #   taggable_obj.delete_tag :not_so_spiffy
    def delete_tag(tag_name)
      tags.delete tag_name
    end
  
    # Checks to see if a tag is present
    #   taggable_obj.has_tag? :spiffy #=> true
    def has_tag?(tag_name)
      tags.include? tag_name
    end
  
    # Returns an array of tags.
    #   taggable_obj.tags #=> [:spiffy, :kind_of_spiffy]
    def tags
      @ruport_tags ||= []
    end
   
    # Sets the tags to some array
    #   taggable_obj.tags = [:really_dang_spiffy, :the_most_spiffy]
    def tags=(tags_list)
      @ruport_tags = tags_list
    end

  end
  
end
