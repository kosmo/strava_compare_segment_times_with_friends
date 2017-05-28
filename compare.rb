require 'strava/api/v3'

PER_PAGE = 200
ACCESS_TOKEN = File.read("access_token.txt").strip

def look_for_rate_limit(&block)
  begin
    yield
  rescue => e
    if /Rate Limit Exceeded/ =~ e.message
      puts "Rate Limit Exceeded ... wait" 
      sleep 1500
      yield
    else
      raise e
    end
  end
end

def sort_after_time(segments_with_times)
  segments_with_fastest_times = {}
  
  segments_with_times.each do |segment, riders|
    segments_with_fastest_times[segment] = riders.collect{|k,v| {time: v.first, rider: k } if v.first}.compact.sort_by { |hash| hash.values.first }
  end

  segments_with_fastest_times.delete_if{|k,v| v.length < 2}

  return segments_with_fastest_times
end


@client = Strava::Api::V3::Client.new(:access_token => ACCESS_TOKEN)

friends = {}
segment_ids = []
all_rides = []
page = 1
result = {}
yourself = "kosmo klabauterius"

strava_friends = []
look_for_rate_limit do
#  strava_friends = @client.list_athlete_friends
end

for friend in strava_friends do
  look_for_rate_limit do
    friends[friend["id"]] = @client.retrieve_another_athlete(friend["id"])
  end
end

begin
  activities = []
  look_for_rate_limit do
    activities = @client.list_athlete_activities(per_page: PER_PAGE, page: page) # Filterung nach Datum
  end
  rides = activities.reject { |act| act['type'] != 'Ride' }
  all_rides += rides
  puts "Page #{page} with #{rides.length} rides"
  page += 1
end until activities.length == 0

for ride_summary in all_rides do
  ride = nil
  look_for_rate_limit do
    ride = @client.retrieve_an_activity(ride_summary["id"])
  end
  for segment in ride["segment_efforts"] do
    segment_ids << segment["segment"]["id"]
  end if ride["segment_efforts"]
end

puts "segment ids collected"

segment_ids.uniq!

for segment_id in segment_ids do
  look_for_rate_limit do
    segment = @client.retrieve_a_segment(segment_id)
  end
  result[segment["name"]] = {} unless result[segment["name"]]
  result[segment["name"]]["strava_link"] = "https://www.strava.com/segments/#{segment_id}"

  leaderboard = []
  look_for_rate_limit do
    leaderboard = @client.segment_leaderboards(segment_id, following: true)
  end

  result[segment["name"]]["times"] = []
  
  for athlete in leaderboard["entries"] do
    result[segment["name"]]["times"] << { :athlete_name => athlete["athlete_name"], :elapsed_time => athlete["elapsed_time"] }
  end

  result[segment["name"]]["times"].sort_by!{ |k| k["elapsed_time"] }
  if result[segment["name"]]["times"].first[:athlete_name] != yourself
    result[segment["name"]]["others_are_faster"] = true
  else
    result[segment["name"]]["others_are_faster"] = false
  end
end

puts result.to_yaml





