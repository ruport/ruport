module Ruport
  
  module Reportable
    
    def formatted_table(type,options={})
      to_table(:find => options[:find],:columns => options[:columns]).as(type){ |e|
        yield(e) if block_given?
      }
    end
    
    def to_table(options={})
      options[:columns] ||= column_names
       Ruport::Data::Table.new(
        :data => find(:all,options[:find]), 
        :column_names => column_names).reorder(*options[:columns])
    end


  end

  class Data::Table
    alias_method :old_append, :<<
    def <<( stuff )
      stuff = stuff.attributes if stuff.kind_of? ActiveRecord::Base
      old_append(stuff)
    end
  end
end

class ActiveRecord::Base
  def self.acts_as_reportable
    extend Ruport::Reportable
  end
end


