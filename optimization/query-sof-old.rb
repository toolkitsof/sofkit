# encoding: utf-8

require 'net/http'
require 'json'
require 'active_support/all'

id = 1212121
site = "stackoverflow"
url_string = "http://api.stackexchange.com/2.2/posts/#{id}?sort=activity&site=#{site}&filter=withBody"
url = URI.parse(url_string)

request = Net::HTTP::Get.new(url.to_s)
puts url.port
response = Net::HTTP.start(url.host, url.port) do |http|
  http.request(request)
end

response_string = ActiveSupport::Gzip.decompress(response.body)
response = JSON.parse(response_string)
puts response['items'].first()['body']