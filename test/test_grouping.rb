require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end

class TestGrouping < Test::Unit::TestCase

  def test_group_constructor
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [[1,2,3]],
                                    :column_names => %w[a b c])
    assert_equal 'test', group.name
    assert_equal Ruport::Data::Record.new([1,2,3],:attributes => %w[a b c]),
      group.data[0]
    assert_equal  %w[a b c], group.column_names
  end

  def test_should_copy_group
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [[1,2,3]],
                                    :column_names => %w[a b c])
    copy = group.dup
    assert_equal 'test', copy.name
    assert_equal Ruport::Data::Record.new([1,2,3],:attributes => %w[a b c]),
      copy.data[0]
    assert_equal  %w[a b c], copy.column_names
  end

  def test_group_as
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [%w[Ruport Is Sexy]],
                                    :column_names => %w[Software Isnt Sexy])
    assert_equal(7,group.to_text.to_a.length)
    assert_equal(5,group.as(:text, :show_group_headers => false).to_a.length)
    assert_equal(13,group.to_html.to_a.length)
  end

  def test_eql
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [%w[ruport is sexy]],
                                    :column_names => %w[software isnt sexy])
    table = [%w[ruport is sexy]].to_table(%w[software isnt sexy])

    group2 = Ruport::Data::Group.new(:name => 'test',
                                     :data => [%w[ruport is sexy]],
                                     :column_names => %w[software isnt sexy])

    assert_raises(NoMethodError) { group == table }
    assert_equal group, group2
    assert_equal group, group.dup
  end

  def test_to_table
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [%w[Ruport Is Sexy]],
                                    :column_names => %w[Software Isnt Sexy])
    table = [%w[Ruport Is Sexy]].to_table(%w[Software Isnt Sexy])

    assert_equal table, group.to_table

  end

end

