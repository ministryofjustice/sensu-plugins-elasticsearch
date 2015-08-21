#!/usr/bin/env ruby
require 'json'
require 'uri'
require 'optparse'
require 'net/http'

options = {}
OptionParser.new do |opts|
  opts.on('-f', '--json-file QUERY_FILE',
          'Location of the json file containing the elasticsearch query') do |f|
    options[:json_file] = f
  end
  opts.on('-w', '--warning THRESHOLD', 'Warning threshold') do |w|
    options[:warning] = w.to_i
  end
  opts.on('-c', '--critical THRESHOLD', 'Critical threshold') do |c|
    options[:critical] = c.to_i
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
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end
rescue Errno::ETIMEDOUT, Net::HTTPGatewayTimeOut
  puts 'UNKNOWN: Timeout waiting for JSON response'
  exit 3
rescue JSON::ParserError
  puts 'UNKNOWN: Parse error in response'
  exit 3
end

json = JSON.parse response.body
# Default to aggregations; use hits if the query does not return an aggregation
# If aggregration is in place then just the first value (as specified in the query) is returned
if json.key? 'aggregations'
  value = json['aggregations'].values[0]['values'].values[0]
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

unless value.is_a?(Float) || value.is_a?(Integer)
  puts "UNKNOWN: query returned a value of #{value} (type: #{value.class}) - was expecting an Integer or Float"
  exit 3
end

if value >= options[:critical]
  puts "CRITICAL: #{value}"
  exit 2
elsif value >= options[:warning]
  puts "WARN: #{value}"
  exit 1
else
  puts "OK: #{value}"
  exit 0
end