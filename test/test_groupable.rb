require "ruport"
require "test/unit"

class Ruport::Data::Table
  include Ruport::Data::Groupable
end

# ticket:96
class TestGroupable < Test::Unit::TestCase
  def test_simple
#    a = [[1,2],[3,4],[5,6],[7,8]].to_table(%w[a b])
#    a[0].tag(:foo); a[1].tag(:bar);
#    a[2].tag(:bar); a[3].tag(:foo);


#    expected = Ruport::Data::Record.new( [ [[1,2],[7,8]].to_table(%w[a b]),
#                                           [[3,4],[5,6]].to_table(%w[a b]) ], 
#                                           :attributes => ["foo","bar"] )
#    assert_equal expected, a.group_by_tag

#    a[0].tag(:bar)

#    expected = Ruport::Data::Record.new( [ [[1,2],[7,8]].to_table(%w[a b]),
#                                           [[1,2],[3,4],[5,6]].to_table(%w[a b]) ], 
#                                           :attributes => ["foo","bar"] )
#    assert_equal expected, a.group_by_tag
  end
end


