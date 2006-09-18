require "test/unit"
require "ruport"

begin; require "rubygems"; rescue LoadError; nil; end

class TestAging < Test::Unit::TestCase

  include Ruport::Report::Aging

  def test_group_by_month
    a = [['2006/06/09','foo'],['2006/05/09','bar'],
         ['2006/06/12','baz'],['2006/02/01','foobar']].to_table(%w[date col])

    assert respond_to?(:group_by_month)
    assert_raise(ArgumentError) { group_by_month(a) }
    b = group_by_month(a,:date_column => "date")
   
    expected = Ruport::Data::Record.new [ [['foo'],['baz']].to_table(%w[col]),
                                          [['bar']].to_table(%w[col]),
                                          [['foobar']].to_table(%w[col]) ], 
                                        :attributes => %w[2006/6 2006/5 2006/2]

    assert_equal expected["2006/6"],b["2006/6"]
    assert_equal expected["2006/5"],b["2006/5"]
    assert_equal expected["2006/2"],b["2006/2"]

  end

end
