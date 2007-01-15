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

  def test_erb
    @report = Report.new
    @report.results = "foo"
    assert_equal "foo", @report.erb("<%= @results %>")
    assert_equal "foo\n4\n---\n", @report.erb("test/samples/foo.rtxt")
  end

  def test_textile
    @report = Report.new
    assert_equal "<p><strong>foo</strong></p>", @report.textile("*foo*")
  end
  
  def test_query
    assert_kind_of Ruport::Data::Table, 
      @report.query("blah",:query_obj => @query1)
    expected = [[1,2,3],[4,5,6],[7,8,9]]
    @report.query("blah",:query_obj => @query1, :yield_type => :by_row) { |r|
      assert_equal expected.shift, r.to_a
      assert_equal %w[a b c], r.attributes
    }
    assert_equal "a,b,c\n1,2,3\n4,5,6\n7,8,9\n", 
       @report.query("blah",:query_obj => @query1, :as => :csv)       
  end

  class MyReport < Report; end
  
  def test_klass_methods
    rep_klass = MyReport.dup
    rep_klass.send(:prepare)  { self.file = "foo.csv" }
    rep_klass.send(:generate) { "hello dolly" }
    rep_klass.send(:cleanup) { @foo = "bar" }
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

    rep_klass.send(:generate) { file }

    expected = %w[foo bar]

    rep_klass.run :reports => [report1,report2] do |rep|
      assert_equal expected.shift, rep.results
    end

  end


  def test_timeout
    rep_klass = MyReport.dup
    rep_klass.send(:generate) { raise }

    assert_raises(RuntimeError){ 
      rep_klass.run(:tries => 3, :interval => 1, :log_level => :log_only)
    }
    
    rep_klass.send(:generate) { sleep 1.1 }

    assert_raises(Timeout::Error) {
      rep_klass.run( :tries    => 2, 
                     :timeout  => 1, 
                     :interval => 1,
                     :log_level => :log_only)
    }

  end
  
  def test_return_value
    rep_klass = MyReport.dup
    rep_klass.send(:generate) { "hello dolly" }

    # single report
    assert_equal "hello dolly", rep_klass.run 

    # multiple reports
    assert_equal ["hello dolly", "hello dolly"],
      rep_klass.run(:reports => [rep_klass.new,rep_klass.new])
  end

end
