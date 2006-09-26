require "generator"
require "ruport/query/sql_split"

module Ruport
  
  # Query offers a way to interact with databases via DBI.  It supports
  # returning result sets in either Ruport's native Data::Table, or in their raw
  # form as DBI::Rows.
  #
  # It offers basic caching support, the ability to instantiate a generator for
  # a result set, and the ability to quickly and easily swap between data
  # sources.
  class Query 
    
    
    include Enumerable
    
    # Queries are initialized with some SQL and a number of options that effect
    # their operation.  They are NOT executed at initialization.  
    #
    # This is important to note as they will not query the database until either
    # Query#result, Query#execute, Query#generator, or an enumerable method is
    # called on them. 
    #
    # This kind of laziness is supposed to be A Good Thing, and
    # as long as you keep it in mind, it should not cause any problems.
    #
    # The SQL can be single or multistatement, but the resulting Data::Table will
    # consist only of the result of the last statement which returns something.
    #
    # Options:
    #
    # <tt>:source</tt>  
    #   A source specified in Ruport::Config.sources, defaults to :default
    # <tt>:origin</tt>  
    #   query origin, default to :string, but can be
    #   set to :file, loading the path specified by the sql parameter
    # <tt>:dsn</tt>
    #   If specifed, the query object will manually override Ruport::Config
    # <tt>:user</tt>
    #   If a DSN is specified, a user can be set by this option
    # <tt>:password</tt>
    #   If a DSN is specified, a password can be set by this option
    # <tt>:raw_data</tt>
    #   When set to true, DBI::Rows will be returned
    # <tt>:cache_enabled</tt>
    #   When set to true, Query will download results only once, and then return
    #   cached values until cache has been cleared.
    # Examples:
    #   
    #   # uses Ruport::Config's default source
    #   Ruport::Query.new("select * from fo")
    #   
    #   # uses the Ruport::Config's source labeled :my_source
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
    def initialize(sql, options={})
      options = { :source => :default, :origin => :string }.merge(options)
      options[:binding] ||= binding
      options[:origin] = :file if sql =~ /.sql$/
      q = Format.document :data => get_query(options[:origin],sql),
                          :plugin => :text, :class_binding => options[:binding]
      @statements = SqlSplit.new(q)
      @sql = @statements.join
      
      if options[:dsn]
        Ruport::Config.source :temp, :dsn      => options[:dsn],
                                     :user     => options[:user],
                                     :password => options[:password]
        options[:source] = :temp
      end
      
      select_source(options[:source])
      
      @raw_data = options[:raw_data]
      @cache_enabled  = options[:cache_enabled]
      @params = options[:params]
      @cached_data = nil
    end
    
    # set to true to get DBI:Rows, false to get Ruport constructs
    attr_accessor :raw_data
    
    # modifying this might be useful for testing, this is the data stored by
    # ruport when caching
    attr_accessor :cached_data
    
    # this is the original SQL for the Query object
    attr_reader :sql
    
    # This will set the dsn, username, and password to one specified by a label
    # that corresponds to a source in Ruport::Config
    def select_source(label)
      @dsn      = Ruport::Config.sources[label].dsn
      @user     = Ruport::Config.sources[label].user
      @password = Ruport::Config.sources[label].password
    end 
    
    # Standard each iterator, iterates through result set row by row.
    def each(&action) 
      Ruport.log(
        "no block given!", :status => :fatal,
        :level => :log_only, :exception => LocalJumpError 
      ) unless action
      fetch(&action)
    end
    
    # Grabs the result set as a Data::Table or if in raw_data mode, an array of
    # DBI::Row objects
    def result; fetch; end
    
    # Runs the query without returning its results.
    def execute; fetch; nil; end
    
    # clears the contents of the cache
    def clear_cache
      @cached_data = nil
    end

    # clears the contents of the cache and then runs the query, filling the
    # cache with the new result
    def update_cache
      return unless @cache_enabled
      clear_cache; fetch
    end
    
    # Turns on caching.  New data will not be loaded until cache is clear or
    # caching is disabled.
    def enable_caching
      @cache_enabled = true
    end

    # Turns off caching and flushes the cached data
    def disable_caching
      clear_cache
      @cache_enabled = false
    end
    
    # Returns a Data::Table, even if in raw_data mode
    # Does not work with raw data if cache is enabled and filled
    def to_table
      data_flag, @raw_data = @raw_data, false
      data = fetch; @raw_data = data_flag; return data
    end

    # Returns a csv dump of the query
    def to_csv
      Format.table :plugin => :csv, :data => fetch
    end

    # Returns a Generator object of the result set
    def generator
      Generator.new(fetch)
    end

    private
    
    def query_data( query_text, params=@params )
      
      require "dbi"
      
      data = @raw_data ? [] : Data::Table.new
      DBI.connect(@dsn, @user, @password) do |dbh|
        if params
          sth = dbh.execute(query_text,*params)
        else
          sth = dbh.execute(query_text)
        end
        return unless sth.fetchable?
        results = sth.fetch_all  
        data.column_names = sth.column_names unless @raw_data
        results.each { |row| data << row.to_a }
        sth.finish
      end
      data
      rescue NoMethodError; nil
    end 
    
    def get_query(type,query)
      type.eql?(:file) ? load_file( query ) : query
    end
    
    def load_file( query_file )
      begin; File.read( query_file ).strip ; rescue
        Ruport.log "Could not open #{query_file}",
          :status => :fatal, :exception => LoadError
      end
    end
    
    def fetch
      data = nil
      if @cache_enabled and @cached_data
        data = @cached_data
      else
        @statements.each { |query_text| data = query_data( query_text ) }
      end
      data.each { |r| yield(r) } if block_given? 
      @cached_data = data if @cache_enabled
      return data
    end

  end
end
