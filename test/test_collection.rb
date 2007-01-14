require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end
class TestCollection < Test::Unit::TestCase

	def setup
		@ghosts = Ruport::Data::Collection.new %w[inky blinky clyde]
		@ghost_list = [["inky", "blue"],["blinky","red"],["clyde","orange"]]
		@ghost_records = @ghost_list.map {|x| Ruport::Data::Record.new x }
		@ghost_collection = Ruport::Data::Collection.new @ghost_records
		@ghost_table = Ruport::Data::Table.new :data => @ghost_list
	end

	def test_size
		assert_equal 3, @ghosts.length
		assert_equal @ghosts.length, @ghosts.data.length
		assert_equal @ghosts.length, @ghosts.size
		assert_equal @ghosts.length, @ghosts.data.size
	end

  def test_to_table
    assert_equal @ghost_table, @ghost_collection.to_table
  end
  
end
