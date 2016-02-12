#!/usr/bin/env ruby
require 'json'
require 'uri'
require 'optparse'
require 'net/http'


# A percentiles aggregation may have several percentiles, each with its own value
# whereas an avg aggregation will not, and the structure of the json will be 
# subtly different. This function will transparently handle either case
def first_aggregation_value(aggregations={})
  first_val = aggregations.values[0]
  first_val.key?('values') ? first_val['values'].values[0] : first_val.values[0]
end

options = {}
OptionParser.new do |opts|
  opts.on('-f', '--json-file QUERY_FILE',
          'Location of the json file containing the elasticsearch query') do |f|
    options[:json_file] = f
  end
  opts.on('-w', '--warning THRESHOLD', 'Warning threshold') do |w|
    options[:warning] = w.to_f
  end
  opts.on('-n', '--nil', 'When Nil or Null is returned convert it to 0') do |_|
    options[:nil] = true
  end
  opts.on('-c', '--critical THRESHOLD', 'Critical threshold') do |c|
    options[:critical] = c.to_f
  end
  opts.on('-l', '--elasticsearch-location LOCATION',
          'ElasticSearch URL, Example: https://elasticsearch.example.com/es/_all/_search') do |l|
    options[:elasticsearch_location] = l
  end
end.parse!

# It would be nice if OptionParser had a way to mandate options
# Until then, we're stuck with this approach
fail OptionParser::MissingArgument unless options[:json_file]
fail OptionParser::MissingArgument unless options[:warning]
fail OptionParser::MissingArgument unless options[:critical]
fail OptionParser::MissingArgument unless options[:elasticsearch_location]

begin
  json = JSON.parse IO.read options[:json_file]
rescue JSON::ParserError
  puts "UNKNOWN: Parse error when reading JSON file #{options[:json_file]}"
  exit 3
rescue Errno::EACCES
  puts "UNKNOWN: Permission denied when opening json file #{options[:json_file]}"
  exit 3
rescue Errno::ENOENT
  puts "UNKNOWN: File not found when trying to open JSON file #{options[:json_file]}"
  exit 3
end

begin
  uri = URI(options[:elasticsearch_location])
  req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  req.body = JSON.generate json
  http = Net::HTTP.new(uri.hostname, uri.port)
  http.use_ssl = (uri.scheme == "https")
  response = http.request(req)
rescue Errno::ETIMEDOUT, Net::HTTPGatewayTimeOut
  puts 'UNKNOWN: Timeout waiting for JSON response'
  exit 3
rescue JSON::ParserError
  puts 'UNKNOWN: Parse error in response'
  exit 3
end

begin
  json = JSON.parse response.body
rescue JSON::ParserError
  puts "UNKNOWN: Parse error in response: #{response.body}"
  exit 3
end
# Default to aggregations; use hits if the query does not return an aggregation
# If aggregration is in place then just the first value (as specified in the query) is returned
if json.key? 'aggregations'
  value = first_aggregation_value(json['aggregations'])
    # If we get a value of NaN for aggregations because we have no results to
    # aggregate, we return zero instead
   if value == 'NaN' && json['hits']['total'] == 0
     value = 0
   end
elsif json.key? 'hits'
  value = json['hits']['total']
else
  if json.key? 'timed_out'
    puts 'UNKNOWN: search timed out'
    exit 3
  end
  puts "UNKNOWN: Unable to process the elasticsearch response, is the query correct? (response is #{json})"
  exit 3
end

if value.is_a?(NilClass) && options[:nil]
  value = 0
end

unless value.is_a?(Float) || value.is_a?(Integer)
  puts "UNKNOWN: query returned a value of #{value} (type: #{value.class}) - was expecting an Integer or Float"
  exit 3
end

value = value.round(2) if value.is_a?(Float)
if value >= options[:critical]
  puts "CRITICAL: #{value} exceeds threshold of #{options[:critical]}"
  exit 2
elsif value >= options[:warning]
  puts "WARN: #{value} exceeds threshold of #{options[:warning]}"
  exit 1
else
  puts "OK: #{value}"
  exit 0
end
