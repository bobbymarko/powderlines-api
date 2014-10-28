# Test urls:
# http://localhost:9292
# http://localhost:9292/stations
# http://localhost:9292/station/672:WA:SNTL
# http://localhost:9292/closest_stations?lat=47.3974&lng=-121.3958&data=true&days=3&count=3

class Snotel < Sinatra::Base
  require 'net/http'
  require 'csv'
  require 'json'
  helpers Sinatra::Jsonp

  get '/' do
    haml :index
  end
  
  get '/stations' do
    stations = Station.all
    data = stations.map do |station|
      station.attributes
    end
    jsonp data
  end

  get '/station/:id' do
    id = params[:id] #672
    days = params[:days] || 5
    start_date = params[:start_date] || false
    end_date = params[:end_date] || params[:start_date]
    station = Station.find_by_triplet(id)

    jsonp :station_information => station.attributes, :data => get_data(id, days, start_date, end_date)
  end
  
  get '/closest_stations' do
    lat = params[:lat].to_f
    lng = params[:lng].to_f
    days = params[:days] || 5
    count = params[:count].to_i || 3
    # limit count to 10
    count = 10 if count > 10
    # data determines whether we fetch snow data for the stations
    data = params[:data] ? true : false
    
    stations = Array.new
    
    Station.all.each do |station|
      distance = Haversine.distance(lat, lng, station.location["lat"].to_f, station.location["lng"].to_f).to_miles
      stations << { 
        :station_information => station.attributes,
        :distance => distance
      }
    end
    
    stations = stations.sort_by{|x| x[:distance] }.take(count)
    
    if data
      stations.each do |station|
        station[:data] = get_data(station[:station_information]["triplet"], days)
      end
    end

    jsonp stations
  end
  
  private
  
  def get_data(id, days, start_date = false, end_date = false)
    # data sourced from http://www.wcc.nrcs.usda.gov/reportGenerator
    
    # http://www.wcc.nrcs.usda.gov/reportGenerator/view/customSingleStationReport/daily/549:NV:SNTL%7Cid=%22%22%7Cname/2013-01-15,2013-01-18/SNWD::value
    # http://www.wcc.nrcs.usda.gov/reportGenerator/view_csv/customSingleStationReport/daily/#{id}%7Cid%3D%22%22%7Cname/-#{days}%2C0/WTEQ%3A%3Avalue%2CWTEQ%3A%3Adelta%2CSNWD%3A%3Avalue%2CSNWD%3A%3Adelta

    if start_date
      date = "#{start_date},#{end_date}"
    else
      date = "-#{days}"
    end

    uri = URI("http://www.wcc.nrcs.usda.gov/reportGenerator/view_csv/customSingleStationReport/daily/#{id}%7Cid%3D%22%22%7Cname/#{date}%2C0/WTEQ%3A%3Avalue%2CWTEQ%3A%3Adelta%2CSNWD%3A%3Avalue%2CSNWD%3A%3Adelta")
    json = Net::HTTP.get(uri)
    json_filtered = json.gsub(/(^#.+|#)/, '').gsub(/^\s+/, "") # remove comments at top of file
    
    lines = CSV.parse(json_filtered)
    keys = lines.delete lines.first
     
    data = lines.map do |values|
      Hash[keys.zip(values)]
    end
    
    return data
  end
  
end

class Station < StaticModel::Base
  attr_accessor :distance
  set_data_file 'stations.yml'
end