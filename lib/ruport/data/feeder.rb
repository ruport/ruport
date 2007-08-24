class Ruport::Data::Feeder
   
  def initialize(data)   
    @data = data   
    @constraints = []
  end                  
  
  attr_reader :data
  
  def <<(element)  
    feed_element = data.feed_element(element)
     
    @constraints.each do |type,block|
      if type == :filter
        return self unless block[feed_element]
      else
        block[feed_element]
      end
    end
    
    data << feed_element
    return self
  end
  
  def filter(&block)
    @constraints << [:filter,block]
  end 
  
  def transform(&block)
    @constraints << [:transform,block]
  end
  
end