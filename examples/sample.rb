require "ruport"

class Sample < Ruport::Report

  renders_with Ruport::Renderer::Table
  
  def generate
    Table(%w[a b c]) << [1,2,3] << [4,5,6]
  end

end

if __FILE__ == $0
  report = Sample.new(:csv)
  puts report.run
end
