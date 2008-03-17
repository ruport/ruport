 %w[ruport hpricot open-uri].each { |lib| require lib }

class TracSummaryReport
  
  include Ruport::Controller::Hooks
  
  renders_as_table
  
  def initialize(options={})
    @days = options[:days] || 7
    @timeline_uri = options[:timeline_uri]
  end

  class TicketStatus < Ruport::Data::Record

    def closed
      title =~ /Ticket.+(\w+ closed)/ ? 1 : 0
    end

    def opened
      title =~ /Ticket.+(\w+ created)|(\w+ reopened)/ ? 1 : 0
    end

  end

  def feed_data
    uri = @timeline_uri + "?wiki=on&milestone=on&ticket=on&changeset=on"+
     "&max=10000&daysback=#{@days-1}&format=rss" 
     
    feed = Hpricot(open(uri))  
    
    table = Table([:title, :date], :record_class => TicketStatus) do |table|
      (feed/"item").each do |r|
         title = (r/"title").innerHTML
         next unless title =~ /Ticket.*(created|closed|reopened)/
         table <<  { :title => title,
                     :date  => Date.parse((r/"pubdate").innerHTML) }
       end
    end     
    
    Grouping(table,:by => :date)
  end

  def renderable_data(format)
    summary = feed_data.summary :date,
      :opened => lambda { |g| g.sigma { |r| r.opened  } },
      :closed => lambda { |g| g.sigma { |r| r.closed  } },
      :order => [:date,:opened,:closed] 
      
    summary.sort_rows_by! { |r| r.date }
    return summary
  end
end

timeline = "http://stonecode.svnrepository.com/ruport/trac.cgi/timeline"

report = TracSummaryReport.new(:timeline_uri => timeline, :days => 30)  
puts report.as(:text)

