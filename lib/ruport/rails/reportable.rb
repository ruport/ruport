module Ruport
  
  module Reportable
    
    def formatted_table(type,options={})
      to_ds(:find => options[:find],:columns => options[:columns]).as(type){ |e|
        yield(e) if block_given?
      }
    end
    
    def to_ds(options={})
     options[:columns] ||= column_names
     find(:all,options[:find]).
       to_ds(column_names).select_columns(*options[:columns])
    end

  end

  class DataSet
    
    alias_method :old_append, :<<
    def <<( stuff, filler=@default )
      if stuff.kind_of?(ActiveRecord::Base)
        @data << stuff.attributes
      else
        old_append(stuff,filler)
      end
    end

  end
end

class ActiveRecord::Base
  def self.acts_as_reportable
    extend Ruport::Reportable
  end
end


