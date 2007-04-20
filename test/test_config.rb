require "test/unit"
require "ruport"

class TestConfiguration < Test::Unit::TestCase

  def setup
    Ruport::Config.log_file = "test/unit.log"
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
  
  def test_adding_custom_accessors
    Ruport::Config.my_new_setting = 'blinky'
    assert_equal('blinky', Ruport::Config.my_new_setting)
    Ruport::Config.my_new_setting = 'clyde'
    assert_equal('clyde', Ruport::Config.my_new_setting)
    
    Ruport::Config.my_other_new_setting 'inky'
    assert_equal('inky', Ruport::Config.my_other_new_setting)
    Ruport::Config.my_other_new_setting 'sue'
    assert_equal('sue', Ruport::Config.my_other_new_setting)
  end
  
end
