#tc_report.rb
#
#  Created by Gregory Thomas Brown on 2005-08-09
#  Copyright 2005 (Gregory Brown) All rights reserved.

require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end
class TestReport < Test::Unit::TestCase
  include Ruport

  def setup
    @report = Report.new
    Ruport::Config.source :default, :dsn => "ruport:test", :user => "foo", :password => "bar" 
    @query1 = Ruport::Query.new "select * from foo", :cache_enabled => true 
    @query1.cached_data = [[1,2,3],[4,5,6],[7,8,9]].to_table(%w[a b c]) 
  end
  
  def test_process_text
    result = @report.process_text "<%= 2 + 3 %>", 
                            :filters => [:erb]
    assert_equal("5",result)
    
    if defined? RedCloth
      result = @report.process_text '"foo":http://foo.com', 
                               :filters => [:red_cloth]
                            
      assert_equal('<p><a href="http://foo.com">foo</a></p>',result)
      result = @report.process_text %{"<%= 2 + 3%>":http://foo.com },
                              :filters => [:erb, :red_cloth]
      assert_equal('<p><a href="http://foo.com">5</a></p>',result)
    end
  end

  def test_query
    assert_kind_of Ruport::Data::Table, 
      @report.query("blah",:query_obj => @query1)
    expected = [[1,2,3],[4,5,6],[7,8,9]]
    @report.query("blah",:query_obj => @query1, :yield_type => :by_row) { |r|
      assert_equal expected.shift, r.data
      assert_equal %w[a b c], r.attributes
    }
    assert_equal "a,b,c\n1,2,3\n4,5,6\n7,8,9\n", 
       @report.query("blah",:query_obj => @query1, :as => :csv)
  end

  class MyReport < Report; end
  
  def test_klass_methods
    rep_klass = MyReport.dup
    rep_klass.prepare  { self.file = "foo.csv" }
    rep_klass.generate { "hello dolly" }
    rep_klass.cleanup { @foo = "bar" }
    report = rep_klass.new
    report.run { |rep|  
      assert_equal("foo.csv",rep.file)
      assert_equal("hello dolly",rep.results)
      assert_equal(nil,rep.instance_eval("@foo"))
    }
    assert_equal("bar",report.instance_eval("@foo"))
  end

  def test_multi_reports
    rep_klass = MyReport.dup
    
    report1 = rep_klass.new
    report2 = rep_klass.new

    report1.file = "foo"
    report2.file = "bar"

    rep_klass.generate { file }

    expected = %w[foo bar]

    rep_klass.run(report1,report2) do |rep|
      assert_equal expected.shift, rep.results
    end

  end

end
