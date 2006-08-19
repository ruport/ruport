require "test/unit"
require "ruport"

class TestCollection < Test::Unit::TestCase

	def setup
		@ghosts = Ruport::Data::Collection.new %w[inky blinky clyde]
	end

	def test_size
		assert_equal 3, @ghosts.length
		assert_equal @ghosts.length, @ghosts.data.length
		assert_equal @ghosts.length, @ghosts.size
		assert_equal @ghosts.length, @ghosts.data.size
	end

end
