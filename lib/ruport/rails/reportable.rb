module Ruport

  # This module is designed to be mixed in with an ActiveRecord model
  # to add easy conversion to ruport data structures.
  #
  # In the ActiveRecord Model you wish to integrate with report, add the 
  # following line just below the class definition:
  #
  #   acts_as_reportable
  #
  # This will automatically make all the methods in this module available
  # in the model.
  module Reportable
    
    # Converts the models' data into a Ruport::Data::Table, then renders
    # it using the requested plugin. If :find is specified as an option
    # it is passed directly on to ActiveRecords find method
    #
    #   User.formatted_table(:pdf, :find => {:conditions => "age > 18"})
    def formatted_table(type,options={})
      to_table(:find => options[:find],:columns => options[:columns]).as(type){ |e|
        yield(e) if block_given?
      }
    end
    
    # Converts the models' data into a Ruport::Data::Table object
    # If :find is supplied as an option it is passed directly on to
    # the models find method.
    #
    #   data = User.to_table(:find => {:conditions => "age > 18"})
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

# Extend rails ActiveRecord::Base class to add the option of mixing in
# the Ruport::Reportable Module in the standard rails way
class ActiveRecord::Base
  def self.acts_as_reportable
    extend Ruport::Reportable
  end
end


