#!/usr/local/bin/ruby -w

require "test/unit"
require "ruport"

class TestSet < Test::Unit::TestCase
  include Ruport::Data
  
  def setup
    @empty_set = Set.new
    @set = Set.new :data => [%w[shirt box onion]]
  end
  
  def test_constructor
    assert_not_nil @empty_set

    assert_not_nil @set
    assert_not_nil @set.data
  end
  
  def test_set_is_a_collection
    assert_kind_of Ruport::Data::Collection, @set
  end
  
  def test_equality
    assert_equal @set, Set.new(:data => [%w[shirt box onion]])
    assert_not_equal @set, Set.new(:data => [%w[hat bucket turnip]])
  end
  
  def test_append_record
    s = Set.new
    assert s.data.empty?
    s << Record.new([1,2,3])
    assert_equal [Record.new([1,2,3])], s.data.to_a
  end
  
  def test_append_array
    s = Set.new
    assert s.data.empty?
    s << [1,2,3]
    assert_equal [Record.new([1,2,3])], s.data.to_a
  end
  
  def test_dup
    assert_not_equal @set.data.object_id, @set.dup.data.object_id
  end
  # def test_append_hash
  #   s = Set.new
  #   assert s.data.empty?
  #   s << {:a => 1, :b => 2, :c => 3}
  #   assert_equal [Record.new([1,2,3], :attributes => [:a,:b,:c])], s.data.to_a
  # end
  
  def test_union
    set = Set.new
    set << %w[ a b c ] << %w[ x y z ]
  
    set2 = Set.new
    set2 << %w[ a b c ] << ["d","","e"]
    
    set3 = set | set2
    assert_kind_of(Set, set3)
    assert_equal(set3.data.length, 3)
    assert_equal(Set.new(:data => [ %w[a b c], %w[x y z], ["d","","e"] ]), set3)
    assert_equal((set | set2), set.union(set2))
  end
  
  def test_difference
    set = Set.new
    set << %w[ a b c ]  << %w[x y z] << [1,2,3]

    set2 = Set.new
    set2 << %w[ a b c ]
  
    set3 = set - set2
    assert_kind_of(Set, set3)
    assert_equal(2, set3.data.length)
    assert_equal(Set.new(:data => [ %w[x y z], [1,2,3] ]), set3)
    assert_equal((set - set2), set.difference(set2))
  end

  def test_intersection
    set = Set.new
    set << %w[ a b c ]  << %w[x y z] << [1,2,3]

    set2 = Set.new
    set2 << %w[ a b c ]
  
    set3 = set & set2
    assert_kind_of(Set, set3)
    assert_equal(1, set3.data.length)
    assert_equal(Set.new(:data => [ %w[a b c] ]), set3)
    assert_equal((set & set2), set.intersection(set2))
  end
  
end
