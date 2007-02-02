require "ruport"
require "test/unit"

class Ruport::Data::Table
  include Ruport::Data::Groupable
end

# ticket:96
class TestGroupable < Test::Unit::TestCase
  def test_simple
    a = [[1,2],[3,4],[5,6],[7,8]].to_table(%w[a b])
    a[0].tag("grp_foo"); a[1].tag("grp_bar");
    a[2].tag("grp_bar"); a[3].tag("grp_foo");


    expected = Ruport::Data::Record.new( [ [[1,2],[7,8]].to_table(%w[a b]),
                                           [[3,4],[5,6]].to_table(%w[a b]) ], 
                                           :attributes => %w[foo bar] )
    assert_equal expected, a.groups

    a[0].tag("grp_bar")

    expected = Ruport::Data::Record.new( [ [[1,2],[7,8]].to_table(%w[a b]),
                                           [[1,2],[3,4],[5,6]].to_table(%w[a b]) ], 
                                           :attributes => ["foo","bar"] )
    assert_equal expected, a.groups
  end

  def test_create_group
    a = [[1,2,3],[4,5,6],[7,8,9]].to_table(%w[a b c]) 
    expected = Ruport::Data::Record.new( [ [[1,2,3],[7,8,9]].to_table(%w[a b c]),
                                          [[4,5,6]].to_table(%w[a b c]) ],
                                           :attributes => %w[starts_odd starts_even])
    a.create_group("starts_odd") { |r| (r[0] % 2) != 0 }
    a.create_group(:starts_even) { |r| (r[0] % 2).zero? }

    assert_equal expected, a.groups 
    assert_equal([[1,2,3],[7,8,9]].to_table(%w[a b c]), a.group("starts_odd"))
    assert_equal([[1,2,3],[7,8,9]].to_table(%w[a b c]), a.group(:starts_odd)) 
    assert_equal([[4,5,6]].to_table(%w[a b c]), a.group("starts_even"))
    
  end  

end
