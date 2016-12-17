# Test urls:
# http://localhost:9292
# http://localhost:9292/stations
# http://localhost:9292/station/672:WA:SNTL
# http://localhost:9292/closest_stations?lat=47.3974&lng=-121.3958&data=true&days=3&count=3

class Snotel < Sinatra::Base
  require 'net/http'
  require 'csv'
  require 'json'
  require 'newrelic_rpm'
  helpers Sinatra::Jsonp
  # set :show_exceptions, false

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
    id = params[:id] #672:WA:SNTL
    days = params[:days] || 5
    start_date = params[:start_date] || false
    end_date = params[:end_date] || params[:start_date]
    station = Station.find_by_triplet(id) || halt(404)

    jsonp :station_information => station.attributes, :data => get_data(id, days, start_date, end_date)
  end
  
  get '/closest_stations' do
    lat = params[:lat] ? params[:lat].to_f : halt(400)
    lng = params[:lng] ? params[:lng].to_f : halt(400)
    days = params[:days] ? params[:days].to_i : 5
    count = params[:count] ? params[:count].to_i : 3
    # limit count to 10
    if count > 10
      count = 10
    end
    # data determines whether we fetch snow data for the stations
    data = params[:data] == 'true' ? true : false
    
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
  
  get '/deepest_stations' do
    count = params[:count] ? params[:count].to_i : 10
    
    stations = Array.new
    
    Station.all.each do |station| # This will never work with a 29 second timeout. Need to find a better way.
      stations << { 
        :station_information => get_data(station.attributes["triplet"], 1)
      }
    end
    
    stations = stations.sort_by{|x| x[:station_information]["Snow Depth (in)"] }.take(count)
    

    jsonp stations
  end
  
  error Rack::Timeout::RequestTimeoutError do
    NewRelic::Agent.instance.error_collector.notice_error 'RequestTimeoutError',
      uri: request.path,
      referer: request.referer,
      request_params: request.params
    halt 503, { 'Content-Type' => 'application/json' }, JSON.dump({
      message: "Sorry, but SNOTEL is taking longer than 30 seconds to respond to us. Please try again."
    })
  end
  
  private
  
  def get_data(id, days, start_date = false, end_date = false)
    # data sourced from http://www.wcc.nrcs.usda.gov/reportGenerator
    
    # http://wcc.sc.egov.usda.gov/reportGenerator/view_csv/customSingleStationReport/daily/549:NV:SNTL%7Cid=%22%22%7Cname/2013-01-15,2013-01-18/SNWD::value
    # http://wcc.sc.egov.usda.gov/reportGenerator/view_csv/customSingleStationReport/daily/#{id}%7Cid%3D%22%22%7Cname/-#{days}%2C0/WTEQ%3A%3Avalue%2CWTEQ%3A%3Adelta%2CSNWD%3A%3Avalue%2CSNWD%3A%3Adelta

    # Each parameter on the end adds a new data field to the report: 
    # WTEQ::value (snow water equivalent)
    # WTEQ::delta (change in snow water equivalent)
    # SNWD::value (snow depth)
    # SNWD::delta (change in snow depth)
    # TOBS::value (observed air temperature)

    if start_date
      date = "#{start_date},#{end_date}"
    else
      date = "-#{days}"
    end

    uri = URI("https://wcc.sc.egov.usda.gov/reportGenerator/view_csv/customSingleStationReport/daily/#{id}%7Cid%3D%22%22%7Cname/#{date}%2C0/WTEQ%3A%3Avalue%2CWTEQ%3A%3Adelta%2CSNWD%3A%3Avalue%2CSNWD%3A%3Adelta%2CTOBS%3A%3Avalue")
    json = Net::HTTP.get(uri)
    
    json_filtered = json.gsub(/(^#.+|#)/, '').gsub(/^\s+/, "") # remove comments at top of file
    
    lines = CSV.parse(json_filtered)
    keys = lines.delete lines.first
    
    # The USDA changes the names of the keys in 2016 so we convert them back to their old names    
    keys.map! do |key|
      case key
        when "Snow Water Equivalent (in) Start of Day Values"
          key = "Snow Water Equivalent (in)"
        when "Change In Snow Water Equivalent (in)"
          key = "Change In Snow Water Equivalent (in)"
        when "Snow Depth (in) Start of Day Values"
          key = "Snow Depth (in)"
        when "Change In Snow Depth (in)"
          key = "Change In Snow Depth (in)"
        when "Air Temperature Observed (degF) Start of Day Values"
          key = "Observed Air Temperature (degrees farenheit)"
        else
          key = key
      end
    end
     
    data = lines.map do |values|
      Hash[keys.zip(values)]
    end
    
    return data
  end
  
end

class Station < StaticModel::Base
  attr_accessor :distance
  set_data_file 'config/stations.yml'
end