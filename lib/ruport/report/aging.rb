module Ruport
  class Report
    module Aging
      def group_by_month(data,options={})
        raise ArgumentError unless options[:date_column]
        data = data.dup
        dates = data.map { |r| Date.parse(r[options[:date_column]]) }
        distinct_months = dates.map { |d| [d.year,d.month] }.uniq
        a = distinct_months.inject([]) { |s,m| 
          table = data.select { |r|
            d = Date.parse(r[options[:date_column]])
            m.eql? [d.year, d.month]
          }
          s + [table.to_table(data.column_names)]
        }
        a.each { |t| t.remove_column(options[:date_column]) }
        att = distinct_months.map { |d| d.join("/") }
        Data::Record.new a, :attributes => att
        
      end
    end
  end
end
