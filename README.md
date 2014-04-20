powderlines-api
===============

API for accessing SNOTEL stations. Useful for finding current snow levels across a state. All endpoints accept a callback parameter for JSONP.

To run locally - clone the repo, run "bundle install", run 'rackup', navigate to http://localhost:9292

Access list of 800+ SNOTEL stations:

http://snotel.herokuapp.com/stations

Fetch snow info for a particular station:

http://snotel.herokuapp.com/station/791:WA:SNTL?days=20

params:

Pass the station's triplet. Can be found through the /stations endpoint.

days (integer) - number of day's information to retrieve from today.




Find closest station to a particular lat/long:

http://snotel.herokuapp.com/closest_stations?lat=47.3974&lng=-121.3958&data=true&days=3&count=3

params:

lat (float) - latitude to base search off of. (required)

lng (float) - longitude to base search off of. (required)

data (boolean) - setting to true will enable fetching of snow info from the stations. Note that this might be slow depending on the number of stations you're requesting information from.

days (integer)- number of day's information to retrieve from today.

count - number of station's to return (defaults to 3, maximum of 5)
