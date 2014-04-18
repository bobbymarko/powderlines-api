class Snotel < Sinatra::Base
  require 'net/http'
  require 'csv'
  require 'json'
  helpers Sinatra::Jsonp

  get '/' do
    haml :index
  end

  get '/station/:id' do
    id = params[:id] #672
    days = params[:days] || 5
    
    uri = URI("http://www.wcc.nrcs.usda.gov/reportGenerator/view_csv/customSingleStationReport/daily/#{id}%3AWA%3ASNTL%7Cid%3D%22%22%7Cname/-#{days}%2C0/WTEQ%3A%3Avalue%2CWTEQ%3A%3Adelta%2CSNWD%3A%3Avalue%2CSNWD%3A%3Adelta")
    json = Net::HTTP.get(uri)
    json_filtered = json.gsub(/(^#.+|#)/, '').gsub(/^\s+/, "")
    #json_filtered.inspect
    
    #data = SmarterCSV.process(json_filtered)
    #data = CSV.parse(json_filtered)
    #data.inspect
    
    lines = CSV.parse(json_filtered)
    keys = lines.delete lines.first
     
    data = lines.map do |values|
      Hash[keys.zip(values)]
    end
    jsonp data
    
    
    #lines = CSV.open('snow.csv').readlines
    #lines.inspect
    #keys = lines.delete lines.first
     
    #File.open('what', 'w') do |f|
    #  data = lines.map do |values|
    #    Hash[keys.zip(values)]
    #  end
    #  f.puts JSON.pretty_generate(data)
    #end
    
  end
end