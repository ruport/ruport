require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end

class TestGroup < Test::Unit::TestCase

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
    group.create_subgroups("a")
    copy = group.dup
    assert_equal 'test', copy.name
    assert_equal Ruport::Data::Record.new([1,2,3],:attributes => %w[a b c]),
      copy.data[0]
    assert_equal  %w[a b c], copy.column_names

    b = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                        :column_names => %w[b c],
                                        :name => 1 ) }
    assert_equal b, copy.subgroups
  end

  def test_group_as
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [%w[Ruport Is Sexy]],
                                    :column_names => %w[Software Isnt Sexy])
    assert_equal(7,group.to_text.to_a.length)
    assert_equal(5,group.as(:text, :show_table_headers => false).to_a.length)
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
  
  def test_create_subgroups
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [[1,2,3],[4,5,6]],
                                    :column_names => %w[a b c])
    group.create_subgroups("a")
    b = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                  :column_names => %w[b c],
                                  :name => 1 ),
          4 => Ruport::Data::Group.new( :data => [[5,6]],
                                  :column_names => %w[b c],
                                  :name => 4 ) }
    assert_equal b, group.subgroups
  end    
  
  def test_grouped_data
    a = Group(nil, :data => [[1,2,3],[4,5,6]],
              :column_names => %w[a b c]).send(:grouped_data, "a")
    b = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                  :column_names => %w[b c],
                                  :name => 1 ),
          4 => Ruport::Data::Group.new( :data => [[5,6]],
                                  :column_names => %w[b c],
                                  :name => 4 ) }
    assert_equal b, a
  end
  
  def test_kernel_hack
    expected = Ruport::Data::Group.new( :data => [[2,3]],
                                  :column_names => %w[b c],
                                  :name => 1 )
    assert_equal expected, Group(1, :data => [[2,3]],
                                    :column_names => %w[b c]) 
  end      

  def test_as_throws_proper_errors
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [[1,2,3]],
                                    :column_names => %w[a b c])
 
    assert_nothing_raised { group.as(:csv) }
    assert_nothing_raised { group.to_csv }
    assert_raises(Ruport::Renderer::UnknownFormatError) { group.as(:nothing) }
    assert_raises(Ruport::Renderer::UnknownFormatError) { group.to_nothing }
  end

  class MyGroupSub < Ruport::Data::Group; end

  def test_ensure_grouping_subclasses_render_properly
    t = MyGroupSub.new(:column_names => %w[b c],:name => "1") << [2,3]
    assert_equal "1\n\nb,c\n2,3\n", t.to_csv
  end
 
  
end

class TestGrouping < Test::Unit::TestCase
  
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
    a = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    b = Ruport::Data::Grouping.new(a, :by => "a")
    c = [Ruport::Data::Group.new( :data => [[2,3]],
                                  :column_names => %w[b c],
                                  :name => 1 ),
         Ruport::Data::Group.new( :data => [[5,6]],
                                  :column_names => %w[b c],
                                  :name => 4 ),    
         Ruport::Data::Group.new( :data => [],
                                  :column_names => %w[b c],
                                  :name => 2)]
    assert_equal c[0], b[1] 
    assert_equal c[1], b[4]   
    assert_raises(IndexError) { b[2] }                 
  end    
  
  def test_should_copy_grouping
    a = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    b = Ruport::Data::Grouping.new(a, :by => "a")
    c = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                        :column_names => %w[b c],
                                        :name => 1 ),
          4 => Ruport::Data::Group.new( :data => [[5,6]],
                                        :column_names => %w[b c],
                                        :name => 4 ) }
    copy = b.dup
    assert_equal c, copy.data
    assert_equal "a", copy.grouped_by
  end

  def test_append
   a =[[1,2,3],[4,5,6]].to_table(%w[a b c])
   b = Ruport::Data::Grouping.new(a, :by => "a")
   c = [Ruport::Data::Group.new( :data => [[2,3]],
                                 :column_names => %w[b c],
                                 :name => 1 ),
        Ruport::Data::Group.new( :data => [[5,6]],
                                 :column_names => %w[b c],
                                 :name => 4 )]   
   b << a.to_group("hand banana")
   assert_equal b["hand banana"], a.to_group("hand banana")   
   
   assert_raises(ArgumentError) { b << a.to_group("hand banana") }   
  end          
  
  def test_grouping_as
    table = Ruport::Data::Table.new(:data => [%w[Ruport Is Sexy]],
                                    :column_names => %w[Software Isnt Sexy])
    grouping = Ruport::Data::Grouping.new(table, :by => 'Software')
    assert_equal(8,grouping.to_text.to_a.length)
    assert_equal(6,grouping.as(:text, :show_table_headers => false).to_a.length)
  end

  def test_grouped_by
    a = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    b = Grouping(a, :by => "a")
    assert_equal "a", b.grouped_by
  end

  def test_kernel_hack
    a = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    b = Grouping(a, :by => "a")
    c = { 1 => Ruport::Data::Group.new( :data => [[2,3]],
                                  :column_names => %w[b c],
                                  :name => 1 ),
          4 => Ruport::Data::Group.new( :data => [[5,6]],
                                  :column_names => %w[b c],
                                  :name => 4 ) }
    assert_equal c, b.data
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

  def test_slash
    a = Table(%w[first_name last_name id])
    a << %w[ greg brown awesome ]
    a << %w[ mike milner schweet ]
    a << %w[ greg brown sick ]
    g = Grouping(a,:by => %w[first_name last_name])

    sub = (g / "greg")["brown"]
    assert_equal %w[awesome sick], sub.column("id")
  end
  
  def test_as_throws_proper_errors

    a = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    b = Grouping(a, :by => "a")
 
 
    assert_nothing_raised { b.as(:csv) }
    assert_nothing_raised { b.to_csv }
    assert_raises(Ruport::Renderer::UnknownFormatError) { b.as(:nothing) }
    assert_raises(Ruport::Renderer::UnknownFormatError) { b.to_nothing }
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

class MyRecord < Ruport::Data::Record
end
