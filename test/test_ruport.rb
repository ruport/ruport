require "test/unit"
require "fileutils"
require "stringio"
require "ruport"

class TestRuport < Test::Unit::TestCase

  def setup
    Ruport::Config.log_file = "test/complain.log"
    @output = StringIO.new
  end

  def test_file_created
    assert(File.exist?("test/complain.log"))
  end
  
  def test_fatal
    assert_raise(RuntimeError) {
      Ruport::complain "Default problem", :status => :fatal, 
                                          :output => @output
    }
    @output.rewind
    assert_equal("[!!] Default problem\n", @output.read)
  end

  def test_fatal_log_only 
    assert_raise(RuntimeError) {
      Ruport::complain "Default problem", 
      :status => :fatal, :output => @output, :level  => :log_only
    }
    @output.rewind
    assert_equal("",@output.read)
    
  end
  
  def test_warn
    assert_nothing_raised {
      Ruport::complain "Default problem", :output => @output
    }
    @output.rewind
    assert_equal("[!!] Default problem\n",@output.read)
  end

  def test_warn_log_only
    assert_nothing_raised {
      Ruport::complain "Default problem", :output => @output,
                                          :level  => :log_only
    }
    @output.rewind
    assert_equal("",@output.read)
  end

  def teardown
    Ruport::Config.class_eval("@logger").close
    FileUtils.rm("test/complain.log")
  end
  
end
