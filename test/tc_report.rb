#tc_report.rb
#
#  Created by Gregory Thomas Brown on 2005-08-09
#  Copyright 2005 (Gregory Brown) All rights reserved.

require "test/unit"
require "ruport"
class TestReport < Test::Unit::TestCase
  include Ruport

  def setup
      @report = Report.new
  end
  
  def test_render
    result = @report.render "<%= 2 + 3 %>", 
                            :filters => [:erb]
    assert_equal("5",result)
    
    if defined? RedCloth
      result = @report.render '"foo":http://foo.com', 
                               :filters => [:red_cloth]
                            
      assert_equal('<p><a href="http://foo.com">foo</a></p>',result)
      result = @report.render %{"<%= 2 + 3%>":http://foo.com },
                              :filters => [:erb, :red_cloth]
      assert_equal('<p><a href="http://foo.com">5</a></p>',result)
    end
  end

  class MyReport < Report; end
  
  def test_klass_methods
    MyReport.prepare  { self.file = "foo.csv" }
    MyReport.generate { "hello dolly" }
    MyReport.cleanup { @foo = "bar" }
    report = MyReport.new
    report.run { |rep|  
      assert_equal("foo.csv",rep.file)
      assert_equal("hello dolly",rep.report)
      assert_equal(nil,rep.instance_eval("@foo"))
    }
    assert_equal("bar",report.instance_eval("@foo"))
  end

end
