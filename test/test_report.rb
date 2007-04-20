#tc_report.rb
#
#  Created by Gregory Thomas Brown on 2005-08-09
#  Copyright 2005 (Gregory Brown) All rights reserved.

require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end

begin
  require 'mocha'
  require 'stubba'
  require 'net/smtp'
rescue LoadError
  $stderr.puts "Warning: Mocha not found -- skipping some Report tests"
end

class SampleReport < Ruport::Report
  renders_with Ruport::Renderer::Table

  def generate
    Table(%w[not abc]) << %w[o r] << %w[one two] << %w[thr ee]
  end
end

class TestReport < Test::Unit::TestCase
  include Ruport

  def setup
    @report = Report.new
    Ruport::Query.add_source :default, :dsn => "ruport:test", 
                                       :user => "foo", :password => "bar" 
    @query1 = Ruport::Query.new "select * from foo", :cache_enabled => true 
    @query1.cached_data = [[1,2,3],[4,5,6],[7,8,9]].to_table(%w[a b c]) 
  end

  def test_renders_with_shortcuts
    a = SampleReport.new(:csv)
    assert_equal("not,abc\no,r\none,two\nthr,ee\n",a.run)
    assert_equal("not,abc\no,r\none,two\nthr,ee\n",SampleReport.as(:csv))
    assert_equal("not,abc\no,r\none,two\nthr,ee\n",SampleReport.to_csv)
    assert_equal("not,abc\no,r\none,two\nthr,ee\n",a.to_csv)
    a = SampleReport.new
    assert_equal("not,abc\no,r\none,two\nthr,ee\n",a.to_csv)

    #not sure if this is 'good behaviour'
    assert_equal :csv, a.format
    a.to_text

    assert_equal :text, a.format
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
      rep_klass.run(:tries => 3, :interval => 1)
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

   def test_write_to_file
     return unless Object.const_defined? :Mocha
     file = mock("file")
 
     File.expects(:open).
       with("foo.csv","w").yields(file).returns(file).at_least_once

     file.expects(:<<).
       with("results").returns(file).at_least_once
     
     @report = Report.new
     assert @report.write("foo.csv", "results")
   end
 
   def test_append_to_file
     return unless Object.const_defined? :Mocha
     file = mock("file")
     
     File.expects(:open).
       with("foo.csv","a").yields(file).returns(file).at_least_once

     file.expects(:<<).
       with("results").returns(file).at_least_once
 
     @report = Report.new
     assert @report.append("foo.csv", "results")
   end
 
   def test_load_csv
     expected = [%w[a b c],['d', nil, 'e']].to_table(%w[col1 col2 col3])
 
     @report = Report.new
     table = @report.load_csv("test/samples/data.csv")
 
     assert_equal expected, table
   end
 
   def test_load_csv_as_array
     expected = [%w[a b c],['d', nil, 'e']]
 
     @report = Report.new
     array = @report.load_csv("test/samples/data.csv", :as => :array)
 
     assert_equal expected, array
   end

   def test_renders_with
    klass = MyReport.dup
    klass.renders_with Ruport::Renderer::Table
    klass.send(:generate) { [[1,2,3],[4,5,6]].to_table(%w[a b c]) }
    a = klass.new(:csv)
    assert_equal "a,b,c\n1,2,3\n4,5,6\n", a.run

    klass.renders_with Ruport::Renderer::Table, :show_table_headers => false
    a = klass.new(:csv)
    assert_equal "1,2,3\n4,5,6\n", a.run
    assert_equal "a,b,c\n1,2,3\n4,5,6\n", a.run(:show_table_headers => true)


   end
 
   def test_renders_as_table
     klass = MyReport.dup
     klass.renders_as_table
     klass.send(:generate) { [[1,2,3],[4,5,6]].to_table(%w[a b c]) }
     a = klass.new(:csv)
     assert_equal "a,b,c\n1,2,3\n4,5,6\n", a.run
   end      
   
   def test_renders_as_row
     klass = MyReport.dup
     klass.renders_as_row
     klass.send(:generate) { [[1,2,3]].to_table(%w[a b c])[0] }
     a = klass.new(:csv)
     assert_equal "1,2,3\n", a.run
   end      
   
   def test_renders_as_group
     klass = MyReport.dup
     klass.renders_as_group
     klass.send(:generate) { [[1,2,3]].to_table(%w[a b c]).to_group("foo") }
     a = klass.new(:csv)
     assert_equal "foo\n\na,b,c\n1,2,3\n", a.run
   end    
   
   def test_renders_as_grouping
     klass = MyReport.dup
     klass.renders_as_grouping
     klass.send(:generate) { 
       Grouping([[1,2,3],[4,5,6]].to_table(%w[a b c]),:by => "a")
     }
     a = klass.new(:csv)
     assert_equal "1\n\nb,c\n2,3\n\n4\n\nb,c\n5,6\n\n", a.run
   end

end
