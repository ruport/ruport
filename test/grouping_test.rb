require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end

class TestGroup < Test::Unit::TestCase

  def setup
    @group = Ruport::Data::Group.new(:name => 'test',
                                     :data => [[1,2,3]],
                                     :column_names => %w[a b c])
  end
  
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
    @group.create_subgroups("a")
    copy = @group.dup
    assert_equal 'test', copy.name
    assert_equal Ruport::Data::Record.new([1,2,3],:attributes => %w[a b c]),
      copy.data[0]
    assert_equal  %w[a b c], copy.column_names

    b = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                        :column_names => %w[b c],
                                        :name => 1 ) }
    assert_equal b, copy.subgroups
  end

  def test_eql
    table = [[1,2,3]].to_table(%w[a b c])

    group2 = Ruport::Data::Group.new(:name => 'test',
                                     :data => [[1,2,3]],
                                     :column_names => %w[a b c])

    assert_raises(NoMethodError) { @group == table }
    assert_equal @group, group2
    assert_equal @group, @group.dup
  end
  
  def test_create_subgroups
    group = @group << [4,5,6]
    group.create_subgroups("a")
    b = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                        :column_names => %w[b c],
                                        :name => 1 ),
          4 => Ruport::Data::Group.new( :data => [[5,6]],
                                        :column_names => %w[b c],
                                        :name => 4 ) }
    assert_equal b, group.subgroups
    
    group.create_subgroups("b")
    c = { 2 => Ruport::Data::Group.new( :data => [[3]],
                                        :column_names => %w[c],
                                        :name => 2 ) }
    d = { 5 => Ruport::Data::Group.new( :data => [[6]],
                                        :column_names => %w[c],
                                        :name => 5 ) }
    assert_equal c, group.subgroups[1].subgroups
    assert_equal d, group.subgroups[4].subgroups
  end    
  
  def test_grouped_data
    a = @group << [4,5,6]
    b = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                        :column_names => %w[b c],
                                        :name => 1 ),
          4 => Ruport::Data::Group.new( :data => [[5,6]],
                                        :column_names => %w[b c],
                                        :name => 4 ) }
    assert_equal b, a.send(:grouped_data, "a")
  end
end

class TestGroupRendering < Test::Unit::TestCase

  def setup
    @group = Ruport::Data::Group.new(:name => 'test',
                                     :data => [[1,2,3]],
                                     :column_names => %w[a b c])
  end

  def test_group_as
    assert_equal(7, @group.to_text.to_a.length)
    assert_equal(5, @group.as(:text,
                              :show_table_headers => false).to_a.length)
    assert_equal(13, @group.to_html.to_a.length)
  end
  
  def test_as_throws_proper_errors
    assert_nothing_raised { @group.as(:csv) }
    assert_nothing_raised { @group.to_csv }
    assert_raises(Ruport::Renderer::UnknownFormatError) {
      @group.as(:nothing) }
    assert_raises(Ruport::Renderer::UnknownFormatError) {
      @group.to_nothing }
  end

  class MyGroupSub < Ruport::Data::Group; end

  def test_ensure_group_subclasses_render_properly
    t = MyGroupSub.new(:column_names => %w[b c],:name => "1") << [2,3]
    assert_equal "1\n\nb,c\n2,3\n", t.to_csv
  end
end
    
class TestGrouping < Test::Unit::TestCase
  
  def setup
    table = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    @grouping = Ruport::Data::Grouping.new(table, :by => "a")
  end
  
  def test_grouping_constructor
    a = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    b = Ruport::Data::Grouping.new(a, :by => "a")
    c = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                        :column_names => %w[b c],
                                        :name => 1 ),
          4 => Ruport::Data::Group.new( :data => [[5,6]],
                                        :column_names => %w[b c],
                                        :name => 4 ) }
    assert_equal c, b.data
  end      
  
  def test_grouping_indexing
    a = [Ruport::Data::Group.new( :data => [[2,3]],
                                  :column_names => %w[b c],
                                  :name => 1 ),
         Ruport::Data::Group.new( :data => [[5,6]],
                                  :column_names => %w[b c],
                                  :name => 4 ),
         Ruport::Data::Group.new( :data => [],
                                  :column_names => %w[b c],
                                  :name => 2)]
    assert_equal a[0], @grouping[1]
    assert_equal a[1], @grouping[4]
    assert_raises(IndexError) { @grouping[2] }
  end    
  
  def test_should_copy_grouping
    a = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                        :column_names => %w[b c],
                                        :name => 1 ),
          4 => Ruport::Data::Group.new( :data => [[5,6]],
                                        :column_names => %w[b c],
                                        :name => 4 ) }
    copy = @grouping.dup
    assert_equal a, copy.data
    assert_equal "a", copy.grouped_by
  end

  def test_append
   a =[[1,2,3],[4,5,6]].to_table(%w[a b c])
   @grouping << a.to_group("red snapper")
   assert_equal @grouping["red snapper"], a.to_group("red snapper")
   
   assert_raises(ArgumentError) { @grouping << a.to_group("red snapper") }
  end
  
  def test_grouped_by
    assert_equal "a", @grouping.grouped_by
  end

  def test_grouping_on_multiple_columns
    a = [[1,2,3,4],[4,5,6,7]].to_table(%w[a b c d])
    b = Ruport::Data::Grouping.new(a, :by => %w[a b c])
    c = { 1 => Ruport::Data::Group.new( :data => [[2,3,4]],
                                        :column_names => %w[b c d],
                                        :name => 1 ),
          4 => Ruport::Data::Group.new( :data => [[5,6,7]],
                                        :column_names => %w[b c d],
                                        :name => 4 ) }
    assert_equal c, b.data

    d = { 2 => Ruport::Data::Group.new( :data => [[3,4]],
                                        :column_names => %w[c d],
                                        :name => 2 ) }
    e = { 5 => Ruport::Data::Group.new( :data => [[6,7]],
                                        :column_names => %w[c d],
                                        :name => 5 ) }
    assert_equal d, b[1].subgroups
    assert_equal e, b[4].subgroups
  end      

  def test_subgrouping
    a = Table(%w[first_name last_name id])
    a << %w[ greg brown awesome ]
    a << %w[ mike milner schweet ]
    a << %w[ greg brown sick ]
    g = Grouping(a,:by => %w[first_name last_name])

    sub = g.subgrouping("greg")["brown"]
    assert_equal %w[awesome sick], sub.column("id")

    sub = (g / "mike")["milner"]
    assert_equal %w[schweet], sub.column("id")
  end
  
  class TicketStatus < Ruport::Data::Record

    def closed
      title =~ /Ticket.+(\w+ closed)/ ? 1 : 0
    end

    def opened
      title =~ /Ticket.+(\w+ created)|(\w+ reopened)/ ? 1 : 0
    end

  end
  
  def test_grouping_summary
    source = Table("test/samples/ticket_count.csv",
                     :record_class => TicketStatus)
    grouping = Grouping(source,:by => "date")
    
    expected = Table(:date, :opened,:closed)
    grouping.each do |date,group|
      opened = group.sigma { |r| r.opened  }
      closed = group.sigma { |r| r.closed  }
      expected << { :date => date, :opened => opened, :closed => closed }
    end
    
    actual = grouping.summary :date,
      :opened => lambda { |g| g.sigma(:opened) },
      :closed => lambda { |g| g.sigma(:closed) },
      :order => [:date,:opened,:closed]
      
    assert_equal expected, actual
    
    actual = grouping.summary :date,
      :opened => lambda { |g| g.sigma(:opened) },
      :closed => lambda { |g| g.sigma(:closed) }
      
    assert_equal [], expected.column_names - actual.column_names
  end   
 
  class MyRecord < Ruport::Data::Record; end
  
  def test_grouping_should_set_record_class
    a = Table(%w[a b c], :record_class => MyRecord) { |t| 
          t << [1,2,3]
          t << [4,5,6]
        }
    b = Ruport::Data::Grouping.new(a, :by => "a")
    assert_equal MyRecord, b[1].record_class
  end   

  class MyGroupingSub < Ruport::Data::Grouping; end

  def test_ensure_grouping_subclasses_render_properly
    t = Table(%w[a b c]) << [1,2,3]
    a = MyGroupingSub.new(t, :by => "a") 
    assert_equal "1\n\nb,c\n2,3\n\n", a.to_csv
  end
end

class TestGroupingRendering < Test::Unit::TestCase

  def setup
    table = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    @grouping = Ruport::Data::Grouping.new(table, :by => "a")
  end
  
  def test_grouping_as
    assert_equal(16, @grouping.to_text.to_a.length)
    assert_equal(12, @grouping.as(:text,
      :show_table_headers => false).to_a.length)
  end

  def test_as_throws_proper_errors
    assert_nothing_raised { @grouping.as(:csv) }
    assert_nothing_raised { @grouping.to_csv }
    assert_raises(Ruport::Renderer::UnknownFormatError) {
      @grouping.as(:nothing) }
    assert_raises(Ruport::Renderer::UnknownFormatError) {
      @grouping.to_nothing }
  end
end

class TestGroupingKernelHacks < Test::Unit::TestCase

  def test_group_kernel_hack
    group = Ruport::Data::Group.new( :name => 'test',
                                     :data => [[1,2,3]],
                                     :column_names => %w[a b c])
    assert_equal group, Group('test', :data => [[1,2,3]],
                                      :column_names => %w[a b c]) 
  end

  def test_grouping_kernel_hack
    table = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    grouping = Ruport::Data::Grouping.new(table, :by => "a")
    a = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                        :column_names => %w[b c],
                                        :name => 1 ),
          4 => Ruport::Data::Group.new( :data => [[5,6]],
                                        :column_names => %w[b c],
                                        :name => 4 ) }
    assert_equal a, grouping.data
  end
end
