require "generator"
require "ruport/query/sql_split"

module Ruport
  
  # === Overview
  # 
  # Query offers a way to interact with databases via DBI. It supports
  # returning result sets in either Ruport's native Data::Table, or in their 
  # raw form as DBI::Rows.
  #
  # It offers basic caching support, the ability to instantiate a generator 
  # for a result set, and the ability to quickly and easily swap between data
  # sources.
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
    # <b><tt>:raw_data</tt></b>::       When set to true, DBI::Rows will be 
    #                                   returned instead of a Data::Table.
    # <b><tt>:cache_enabled</tt></b>::  When set to true, Query will download 
    #                                   results only once, and then return 
    #                                   cached values until the cache has been 
    #                                   cleared.
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
    #   Ruport::Query.new("foo",:origin => :file)
    #
    def initialize(sql, options={})
      options = { :source => :default, :origin => :string }.merge(options)
      options[:origin] = :file if sql =~ /.sql$/
      @statements = SqlSplit.new(get_query(options[:origin],sql))
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

    def self.default_source
      sources[:default]
    end

    def self.sources
      @sources ||= {}
    end

    def self.add_source(name,options={})
      sources[name] = OpenStruct.new(options)
      check_source(sources[name],name)
    end

    private

    def self.check_source(settings,label) # :nodoc:
      raise ArgumentError unless settings.dsn
    end

    public

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
    
    def each(&action)
      raise(LocalJumpError, "No block given!") unless action
      fetch(&action)
      self
    end
    
    def result; fetch; end
    
    # Runs the query without returning its results.
    def execute; fetch; nil; end
    
    # Returns a Data::Table, even if in <tt>raw_data</tt> mode.
    # This doesn't work with raw data if the cache is enabled and filled.
    #
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
            data << row if !block_given? || @cache_enabled
          end
        end
      end
      data
    end
    
    def get_query(type,query)
      type.eql?(:file) ? load_file( query ) : query
    end
    
    def load_file(query_file)
      begin
        File.read( query_file ).strip
      rescue
        raise LoadError, "Could not open #{query_file}"
      end
    end
    
    def fetch(&block)
      data = nil
      final = @statements.size - 1
      @statements.each_with_index do |query_text, index|
        data = query_data(query_text, &(index == final ? block : nil))
      end
      return data
    end
  end
end
