#!/usr/bin/env ruby -w   
require File.join(File.expand_path(File.dirname(__FILE__)), "helpers")

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
    @group.send(:create_subgroups, "a")
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
    table = Table(%w[a b c], :data => [[1,2,3]])

    group2 = Ruport::Data::Group.new(:name => 'test',
                                     :data => [[1,2,3]],
                                     :column_names => %w[a b c])

    assert_raises(NoMethodError) { @group == table }
    assert_equal @group, group2
    assert_equal @group, @group.dup
  end
  
  def test_create_subgroups
    group = @group << [4,5,6]
    group.send(:create_subgroups, "a")
    b = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                        :column_names => %w[b c],
                                        :name => 1 ),
          4 => Ruport::Data::Group.new( :data => [[5,6]],
                                        :column_names => %w[b c],
                                        :name => 4 ) }
    assert_equal b, group.subgroups
    
    group.send(:create_subgroups, "b")
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
    assert_raises(Ruport::Controller::UnknownFormatError) {
      @group.as(:nothing) }
    assert_raises(Ruport::Controller::UnknownFormatError) {
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
    table = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
    @grouping = Ruport::Data::Grouping.new(table, :by => "a")
  end
  
  def test_grouping_constructor
    a = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
    b = Ruport::Data::Grouping.new(a, :by => "a")
    c = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                        :column_names => %w[b c],
                                        :name => 1 ),
          4 => Ruport::Data::Group.new( :data => [[5,6]],
                                        :column_names => %w[b c],
                                        :name => 4 ) }
    assert_equal c, b.data
  end        
  
  def test_empty_grouping
    a = Ruport::Data::Grouping.new()
    a << Group("foo",:data => [[1,2,3],[4,5,6]],
                     :column_names => %w[a b c] )
    assert_equal "foo", a["foo"].name    
    assert_nil a.grouped_by         
  end                               
  
  def test_empty_grouping_with_grouped_by
    a = Ruport::Data::Grouping.new(:by => "nada")  
    a << Group("foo",:data => [[1,2,3],[4,5,6]],
                     :column_names => %w[a b c] )
    assert_equal "foo", a["foo"].name    
    assert_equal "nada", a.grouped_by
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
   a = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
   @grouping << a.to_group("red snapper")
   assert_equal @grouping["red snapper"], a.to_group("red snapper")
   
   assert_raises(ArgumentError) { @grouping << a.to_group("red snapper") }
  end
  
  def test_grouped_by
    assert_equal "a", @grouping.grouped_by
  end

  def test_grouping_on_multiple_columns
    a = Table(%w[a b c d], :data => [[1,2,3,4],[4,5,6,7]])
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
    source = Table(File.join(File.expand_path(File.dirname(__FILE__)), 
                   *%w[samples ticket_count.csv]),
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
  
  def test_grouping_sigma
    assert_respond_to @grouping, :sigma
    assert_respond_to @grouping, :sum
    
    expected = {}
    @grouping.data[@grouping.data.keys.first].column_names.each do |col|
      expected[col] = @grouping.inject(0) do |s, (group_name, group)|
        s + group.sigma(col)
      end
    end
    expected.keys.each do |col|
      assert_equal expected[col], @grouping.sigma(col)
    end

    expected = {}
    @grouping.data[@grouping.data.keys.first].column_names.each do |col|
      expected[col] = @grouping.inject(0) do |s, (group_name, group)|
        s + group.sigma {|r| r[col] + 2 }
      end
    end
    expected.keys.each do |col|
      assert_equal expected[col], @grouping.sigma {|r| r[col] + 2 }
    end
  end

  context "when sorting groupings" do
    
    def setup
      @table = Table(%w[a b c]) << ["dog",1,2] << ["cat",3,5] << 
                                   ["banana",8,1] << ["dog",5,6] << ["dog",2,4] << ["banana",7,9]
    end
    
    def specify_can_set_by_group_name_order_in_constructor
      a = Grouping(@table, :by => "a", :order => :name)    
      names = %w[banana cat dog]           
      data = [ [[8,1],[7,9]], [[3,5]], [[1,2],[5,6],[2,4]] ]
      a.each do |name,group|
        assert_equal names.shift, name
        assert_equal data.shift, group.map { |r| r.to_a } 
      end
    end
    
    def specify_can_set_by_proc_ordering_in_constructor
      a = Grouping(@table, :by => "a", :order => lambda { |g| -g.length } ) 
      names = %w[dog banana cat]      
      data = [ [[1,2],[5,6],[2,4]], [[8,1],[7,9]], [[3,5]] ]
      a.each do |name,group|
        assert_equal names.shift, name
        assert_equal data.shift, group.map { |r| r.to_a } 
      end
    end  
    
    def specify_can_override_sorting
      a = Grouping(@table, :by => "a", :order => lambda { |g| -g.length } )  
      a.sort_grouping_by!(:name)
      names = %w[banana cat dog]           
      data = [ [[8,1],[7,9]], [[3,5]], [[1,2],[5,6],[2,4]] ]
      a.each do |name,group|
        assert_equal names.shift, name
        assert_equal data.shift, group.map { |r| r.to_a } 
      end
    end 
    
    def specify_can_get_a_new_sorted_grouping
      a = Grouping(@table, :by => "a", :order => lambda { |g| -g.length } )  
      b = a.sort_grouping_by(:name)     
      
      names = %w[banana cat dog]           
      data = [ [[8,1],[7,9]], [[3,5]], [[1,2],[5,6],[2,4]] ]
      b.each do |name,group|
        assert_equal names.shift, name
        assert_equal data.shift, group.map { |r| r.to_a } 
      end
      
      # assert original retained
      names = %w[dog banana cat]      
      data = [ [[1,2],[5,6],[2,4]], [[8,1],[7,9]], [[3,5]] ]
      a.each do |name,group|
        assert_equal names.shift, name
        assert_equal data.shift, group.map { |r| r.to_a } 
      end   
    end
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
    table = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
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
    assert_raises(Ruport::Controller::UnknownFormatError) {
      @grouping.as(:nothing) }
    assert_raises(Ruport::Controller::UnknownFormatError) {
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
    table = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
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
