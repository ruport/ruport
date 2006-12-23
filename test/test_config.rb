require "test/unit"
require "ruport"

class TestConfiguration < Test::Unit::TestCase

  def setup
    Ruport::Config.log_file = "test/unit.log"
  end
  
  def test_dsn_defaults
    assert_equal(nil, Ruport::Config.default_source)
  end

  def test_mail_defaults
    assert_equal(nil, Ruport::Config.default_mailer)
  end

  def test_missing_dsn
   assert_raise(ArgumentError) {
     Ruport::Config.source :foo, :user => "root", :password => "fff"
   }
   assert_nothing_raised { Ruport::Config.source :bar, :dsn => "..." }
  end

  def test_mailer_errors
    assert_raise(ArgumentError) {
      Ruport::Config.mailer :bar, :user => :foo, :address => "foo@bar.com"
    }
    assert_nothing_raised { Ruport::Config.mailer :bar, :host => "localhost" }
  end

  def test_new_defaults
   Ruport::Config.source :default, :dsn      => "dbi:mysql:test",
                                   :user     => "root",
                                   :password => ""
   assert_equal("dbi:mysql:test", Ruport::Config.default_source.dsn)
   assert_equal("root", Ruport::Config.default_source.user)
   assert_equal("", Ruport::Config.default_source.password)
  end

  def test_multiple_sources
    Ruport::Config.source :foo, :dsn => "dbi:mysql:test"
    Ruport::Config.source :bar, :dsn => "dbi:mysql:test2"
    assert_equal("dbi:mysql:test",  Ruport::Config.sources[:foo].dsn)
    assert_equal("dbi:mysql:test2", Ruport::Config.sources[:bar].dsn)
  end

  def test_simple_interface
    Ruport.configure do |c|
      c.source :foo, :dsn => "dbi:odbc:test"
      c.source :bar, :dsn => "dbi:odbc:test2"
    end
    assert_equal("dbi:odbc:test",Ruport::Config.sources[:foo].dsn)
    assert_equal("dbi:odbc:test2",Ruport::Config.sources[:bar].dsn)
  end
    

  def test_logger
    # We have a logger running now, dont we?
    assert(Ruport::Config.logger.kind_of?(Logger)) 
      
    # And then we change are mind again.  Back logging?
    Ruport::Config.log_file = "test/unit.log"  
    assert(Ruport::Config.logger.kind_of?(Logger))
    
  end

  def test_debug
    assert_equal(false, Ruport::Config.debug_mode?)
    Ruport::Config.debug_mode = true 
    assert_equal(true, Ruport::Config.debug_mode?)
    Ruport::Config.debug_mode = false
    assert_equal(false, Ruport::Config.debug_mode?)
  end
   
end
