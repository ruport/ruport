# Ruport : Extensible Reporting System                                
#
# acts_as_reportable.rb provides ActiveRecord integration for Ruport.
#     
# Originally created by Dudley Flanders, 2006
# Revised and updated by Michael Milner, 2007     
# Copyright (C) 2006-2007 Dudley Flanders / Michael Milner, All Rights Reserved.  
#
# This is free software distributed under the same terms as Ruby 1.8
# See LICENSE and COPYING for details.   
#
require "ruport"
Ruport.quiet { require "active_record" }

module Ruport
  
  # === Overview
  # 
  # This module is designed to allow an ActiveRecord model to be converted to
  # Ruport's data structures.  If ActiveRecord is available when Ruport is
  # loaded, this module will be automatically mixed into ActiveRecord::Base.
  #
  # Add the acts_as_reportable call to the model class that you want to
  # integrate with Ruport:
  #
  #   class Book < ActiveRecord::Base
  #     acts_as_reportable
  #     belongs_to :author
  #   end
  #
  # Then you can use the <tt>report_table</tt> method to get data from the
  # model using ActiveRecord.
  #
  #   Book.report_table(:all, :include => :author)
  #
  module Reportable
    
    def self.included(base) #:nodoc:
      base.extend ClassMethods  
    end
    
    # === Overview
    # 
    # This module contains class methods that will automatically be available
    # to ActiveRecord models.
    #
    module ClassMethods 
      
      # In the ActiveRecord model you wish to integrate with Ruport, add the 
      # following line just below the class definition:
      #
      #   acts_as_reportable
      #
      # Available options:
      #
      # <b><tt>:only</tt></b>::     an attribute name or array of attribute
      #                             names to include in the results, other
      #                             attributes will be excuded.
      # <b><tt>:except</tt></b>::   an attribute name or array of attribute
      #                             names to exclude from the results.
      # <b><tt>:methods</tt></b>::  a method name or array of method names
      #                             whose result(s) will be included in the
      #                             table.
      # <b><tt>:include</tt></b>::  an associated model or array of associated
      #                             models to include in the results.
      #
      # Example:
      # 
      #   class Book < ActiveRecord::Base
      #     acts_as_reportable, :only => 'title', :include => :author
      #   end
      #
      def acts_as_reportable(options = {})
        cattr_accessor :aar_options, :aar_columns

        self.aar_options = options

        include Ruport::Reportable::InstanceMethods
        extend Ruport::Reportable::SingletonMethods
      end
    end
    
    # === Overview
    # 
    # This module contains methods that will be made available as singleton
    # class methods to any ActiveRecord model that calls
    # <tt>acts_as_reportable</tt>.
    #
    module SingletonMethods
      
      # Creates a Ruport::Data::Table from an ActiveRecord find. Takes 
      # parameters just like a regular find.
      #
      # Additional options include:
      #
      # <b><tt>:only</tt></b>::     an attribute name or array of attribute
      #                             names to include in the results, other
      #                             attributes will be excuded.
      # <b><tt>:except</tt></b>::   an attribute name or array of attribute
      #                             names to exclude from the results.
      # <b><tt>:methods</tt></b>::  a method name or array of method names
      #                             whose result(s) will be included in the
      #                             table.
      # <b><tt>:include</tt></b>::  an associated model or array of associated
      #                             models to include in the results.
      # <b><tt>:record_class</tt></b>::  specify the class of the table's
      #                                  records.
      #
      # The same set of options may be passed to the :include option in order to
      # specify the output for any associated models. In this case, the
      # :include option must be a hash, where the keys are the names of the
      # associations and the values are hashes of options.
      #
      # Any options passed to report_table will disable the options set by
      # the acts_as_reportable class method.
      #
      # Example:
      # 
      #   class Book < ActiveRecord::Base
      #     belongs_to :author
      #     acts_as_reportable
      #   end
      #
      #   Book.report_table(:all, :only => ['title'],
      #     :include => { :author => { :only => 'name' } }).as(:html)
      #
      # Returns:
      #
      # an html version of the table with two columns, title from 
      # the book, and name from the associated author.
      #
      # Example:
      # 
      #   Book.report_table(:all, :include => :author).as(:html)
      #
      # Returns:
      #
      # an html version of the table with all columns from books and authors.
      #
      # Note: column names for attributes of included models will be qualified
      # with the name of the association. 
      #
      def report_table(number = :all, options = {})
        only = options.delete(:only)
        except = options.delete(:except)
        methods = options.delete(:methods)
        includes = options.delete(:include)
        #filters = options.delete(:filters) || [ lambda { true } ]
        record_class = options.delete(:record_class) || Ruport::Data::Record
        self.aar_columns = []

        options[:include] = get_include_for_find(includes)
        
        data = [find(number, options)].flatten
        data = data.map {|r| r.reportable_data(:include => includes,
                               :only => only,
                               :except => except,
                               :methods => methods) }.flatten
        #data.select! { |r| filters.all? { |f| f[r] } }

        table = Ruport::Data::Table.new(:data => data,
                                        :column_names => aar_columns,
                                        :record_class => record_class)
        table
      end
      
      # Creates a Ruport::Data::Table from an ActiveRecord find_by_sql.
      #
      # Additional options include:
      #
      # <b><tt>:record_class</tt></b>::  specify the class of the table's
      #                                  records.
      #
      # Example:
      # 
      #   class Book < ActiveRecord::Base
      #     belongs_to :author
      #     acts_as_reportable
      #   end
      #
      #   Book.report_table_by_sql("SELECT * FROM books")
      #
      def report_table_by_sql(sql, options = {})
        record_class = options.delete(:record_class) || Ruport::Data::Record
        self.aar_columns = []

        data = find_by_sql(sql)
        data = data.map {|r| r.reportable_data }.flatten

        table = Ruport::Data::Table.new(:data => data,
                                        :column_names => aar_columns,
                                        :record_class => record_class)
      end

      private
      
      def get_include_for_find(report_option)
        includes = report_option.blank? ? aar_options[:include] : report_option
        if includes.is_a?(Hash)
          result = {}
          includes.each do |k,v|
            if v.empty? || !v[:include]
              result.merge!(k => {})
            else
              result.merge!(k => get_include_for_find(v[:include]))
            end
          end
          result
        elsif includes.is_a?(Array)
          result = {}
          includes.each {|i| result.merge!(i => {}) }
          result
        else
          includes
        end
      end
    end
    
    # === Overview
    # 
    # This module contains methods that will be made available as instance
    # methods to any ActiveRecord model that calls <tt>acts_as_reportable</tt>.
    #
    module InstanceMethods
      
      # Grabs all of the object's attributes and the attributes of the
      # associated objects and returns them as an array of record hashes.
      # 
      # Associated object attributes are stored in the record with
      # "association.attribute" keys.
      # 
      # Passing :only as an option will only get those attributes.
      # Passing :except as an option will exclude those attributes.
      # Must pass :include as an option to access associations.  Options
      # may be passed to the included associations by providing the :include
      # option as a hash.
      # Passing :methods as an option will include any methods on the object.
      #
      # Example:
      # 
      #   class Book < ActiveRecord::Base
      #     belongs_to :author
      #     acts_as_reportable
      #   end
      # 
      #   abook.reportable_data(:only => ['title'], :include => [:author])
      #
      # Returns:
      #
      #   [{'title' => 'book title',
      #     'author.id' => 'author id',
      #     'author.name' => 'author name' }]
      #  
      # NOTE: title will only be returned if the value exists in the table.
      # If the books table does not have a title column, it will not be
      # returned.
      #
      # Example:
      #
      #   abook.reportable_data(:only => ['title'],
      #     :include => { :author => { :only => ['name'] } })
      #
      # Returns:
      #
      #   [{'title' => 'book title',
      #     'author.name' => 'author name' }]
      #
      def reportable_data(options = {})
        options = options.merge(self.class.aar_options) unless
          has_report_options?(options)
        
        data_records = [get_attributes_with_options(options)]
        Array(options[:methods]).each do |method|
          data_records.first[method.to_s] = send(method)
        end
        
        self.class.aar_columns |= data_records.first.keys
        
        data_records =
          add_includes(data_records, options[:include]) if options[:include]
        data_records
      end
      
      private

      # Add data for all included associations
      #
      def add_includes(data_records, includes)
        include_has_options = includes.is_a?(Hash)
        associations = include_has_options ? includes.keys : Array(includes)
        
        associations.each do |association|
          existing_records = data_records.dup
          data_records = []
          
          if include_has_options
            assoc_options = includes[association].merge({
              :qualify_attribute_names => association })
          else
            assoc_options = { :qualify_attribute_names => association }
          end
          
          association_objects = [send(association)].flatten.compact
          
          existing_records.each do |existing_record|
            if association_objects.empty?
              data_records << existing_record
            else
              association_objects.each do |obj|
                association_records = obj.reportable_data(assoc_options)
                association_records.each do |assoc_record|
                  data_records << existing_record.merge(assoc_record)
                end
                self.class.aar_columns |= data_records.last.keys
              end
            end
          end
        end
        data_records
      end
      
      # Check if the options hash has any report options
      # (:only, :except, :methods, or :include).
      #
      def has_report_options?(options)
        options[:only] || options[:except] || options[:methods] ||
          options[:include]
      end

      # Get the object's attributes using the supplied options.
      # 
      # Use the :only or :except options to limit the attributes returned.
      #
      # Use the :qualify_attribute_names option to append the underscored
      # model name to the attribute name as model.attribute
      #
      def get_attributes_with_options(options = {})
        only_or_except =
          if options[:only] or options[:except]
            { :only => options[:only], :except => options[:except] }
          end
        attrs = attributes(only_or_except)
        attrs = attrs.inject({}) {|h,(k,v)|
                  h["#{options[:qualify_attribute_names]}.#{k}"] = v; h
                } if options[:qualify_attribute_names]
        attrs
      end
    end
  end
end

ActiveRecord::Base.send :include, Ruport::Reportable
