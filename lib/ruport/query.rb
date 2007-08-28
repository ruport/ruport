# Ruport : Extensible Reporting System                                
#
# query.rb provides a basic wrapper around RubyDBI for SQL interaction
#
# Original work began by Gregory Brown based on ideas from James Edward Gray II
# in August, 2005.
#
# Copyright (C) 2005-2007, Gregory Brown
# All Rights Reserved.   
#
# This is free software distributed under the same terms as Ruby 1.8
# See LICENSE and COPYING for details.
require "generator"
require "ruport/query/sql_split"

module Ruport
  
  # === Overview
  # 
  # Query offers a way to interact with databases via RubyDBI. It supports
  # returning result sets in either Ruport's Data::Table, or in their 
  # raw form as DBI::Rows.
  #
  # Query allows you to treat your result sets as an Enumerable data structure
  # that plays well with the rest of Ruport.
  #
  # If you are using ActiveRecord, you might prefer our acts_as_reportable
  # extension.       
  #
  class Query 
       
    include Enumerable
    
    # Ruport::Query provides an interface for dealing with raw SQL queries.
    # The SQL can be single or multistatement, but the resulting Data::Table 
    # will consist only of the result of the last statement.
    #
    # Available options:
    #
    # <b><tt>:source</tt></b>::         A source specified in 
    #                                   Ruport::Query.sources, defaults to 
    #                                   <tt>:default</tt>.
    # <b><tt>:dsn</tt></b>::            If specifed, the Query object will 
    #                                   manually override Ruport::Query.
    # <b><tt>:user</tt></b>::           If a DSN is specified, the user can 
    #                                   be set with this option.
    # <b><tt>:password</tt></b>::       If a DSN is specified, the password 
    #                                   can be set with this option.
    # <b><tt>:row_type</tt></b>::       When set to :raw, DBI::Rows will be 
    #                                   returned instead of a Data::Table
    #
    # Examples:
    #   
    #   # uses Ruport::Query's default source
    #   Ruport::Query.new("select * from fo")
    #   
    #   # uses the Ruport::Query's source labeled :my_source
    #   Ruport::Query.new("select * from fo", :source => :my_source)
    #
    #   # uses a manually entered source
    #   Ruport::Query.new("select * from fo", :dsn => "dbi:mysql:my_db",
    #     :user => "greg", :password => "chunky_bacon" )
    #
    #   # uses a SQL file stored on disk
    #   Ruport::Query.new("my_query.sql")
    #
    #   # explicitly use a file, even if it doesn't end in .sql
    #   Ruport::Query.new(:file => "foo")
    #
    def initialize(sql, options={})   
      if sql.kind_of?(Hash)  
        options = { :source => :default }.merge(sql)   
        sql = options[:file] || options[:string]
      else 
        options = { :source => :default, :string => sql }.merge(options)
        options[:file] = sql if sql =~ /.sql$/    
      end                                                 
      origin = options[:file] ? :file : :string      
      
      @statements = SqlSplit.new(get_query(origin,sql))
      @sql = @statements.join
      
      if options[:dsn]
        Ruport::Query.add_source :temp, :dsn      => options[:dsn],
                                        :user     => options[:user],
                                     :password => options[:password]
        options[:source] = :temp
      end
      
      select_source(options[:source])
      
      @raw_data = options[:row_type].eql?(:raw)
      @params = options[:params]
    end
     
    # Returns an OpenStruct with the configuration options for the default
    # database source.
    #
    def self.default_source
      sources[:default]
    end
     
    # Returns a hash of database sources, keyed by label.
    def self.sources
      @sources ||= {}
    end
    
    # Allows you to add a labeled DBI source configuration. 
    #
    # Query objects will use the source labeled <tt>:default</tt>,
    # unless another source is specified.
    #
    # Examples:
    #
    #   # a connection to a MySQL database foo with user root, pass chunkybacon
    #   Query.add_source :default, :dsn => "dbi:mysql:foo", 
    #                              :user => "root",
    #                              :password => "chunkybacon"
    #
    #
    #   # a second connection to a MySQL database bar
    #   Query.add_source :test, :dsn => "dbi:mysql:bar",
    #                           :user => "tester",
    #                           :password => "blinky" 
    #
    # 
    def self.add_source(name,options={})
      sources[name] = OpenStruct.new(options)
      check_source(sources[name],name)
    end

    attr_accessor :raw_data
    
    # The original SQL for the Query object
    attr_reader :sql
    
    # This will set the <tt>dsn</tt>, <tt>username</tt>, and <tt>password</tt> 
    # to one specified by a source in Ruport::Query.
    #
    def select_source(label)
      @dsn      = Ruport::Query.sources[label].dsn
      @user     = Ruport::Query.sources[label].user
      @password = Ruport::Query.sources[label].password
    end 
    
    # Yields result set by row.
    def each(&action)
      raise(LocalJumpError, "No block given!") unless action
      fetch(&action)
      self
    end
    
    # Runs the SQL query and returns the result set 
    def result; fetch; end
    
    # Runs the query without returning its results.
    def execute; fetch; nil; end
    
    # Returns a Data::Table, even if in <tt>raw_data</tt> mode.
    def to_table
      data_flag, @raw_data = @raw_data, false
      data = fetch; @raw_data = data_flag; return data
    end

    # Returns a csv dump of the query.
    def to_csv
      fetch.to_csv
    end

    # Returns a Generator object of the result set.
    def generator
      Generator.new(fetch)
    end

    private
    
    def query_data(query_text, params=@params)

      require "dbi"
      
      data = @raw_data ? [] : Data::Table.new

      DBI.connect(@dsn, @user, @password) do |dbh|
        dbh.execute(query_text, *(params || [])) do |sth|
          # Work-around for inconsistent DBD behavior w/ resultless queries
          names = sth.column_names rescue []
          if names.empty?
            # Work-around for SQLite3 DBD bug
            sth.cancel rescue nil
            return nil
          end
          
          data.column_names = names unless @raw_data

          sth.each do |row|
            row = row.to_a
            row = Data::Record.new(row, :attributes => names) unless @raw_data
            yield row if block_given?
            data << row if !block_given?
          end
        end
      end
      data
    end
    
    def get_query(type,query)
      type.eql?(:file) ? load_file( query ) : query
    end
    
    def fetch(&block)
      data = nil
      final = @statements.size - 1
      @statements.each_with_index do |query_text, index|
        data = query_data(query_text, &(index == final ? block : nil))
      end
      return data
    end
    
    def load_file(query_file)
      begin
        File.read( query_file ).strip
      rescue
        raise LoadError, "Could not open #{query_file}"
      end
    end

    def self.check_source(settings,label) # :nodoc:
      raise ArgumentError unless settings.dsn
    end
    
  end
end
