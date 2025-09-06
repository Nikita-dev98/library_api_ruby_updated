require 'net/http'
require 'uri'
require 'json'
require 'date'

BASE_URL = 'http://127.0.0.1:3000/books'

# ---------- Helper Methods ----------
def log_request(action, response)
  result = {}
  result[:action] = action
  result[:status] = response.code
  begin
    json_body = JSON.parse(response.body)
    puts "-" * 60
    puts "#{action}"
    puts "Status: #{response.code}"
    puts "Response: #{JSON.pretty_generate(json_body)}"
    result[:success] = response.code.to_i.between?(200, 299)
    result[:body] = json_body
  rescue
    puts "-" * 60
    puts "#{action}"
    puts "Status: #{response.code}"
    puts "Response: #{response.body}"
    result[:success] = false
    result[:body] = response.body
  end
  puts "-" * 60
  result
end

def get(uri)
  req = Net::HTTP::Get.new(uri)
  req['Accept'] = 'application/json'
  Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
end

def post(uri, body_hash)
  req = Net::HTTP::Post.new(uri)
  req['Content-Type'] = 'application/json'
  req['Accept'] = 'application/json'
  req.body = body_hash.to_json
  Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
end

def patch(uri, body_hash)
  req = Net::HTTP::Patch.new(uri)
  req['Content-Type'] = 'application/json'
  req['Accept'] = 'application/json'
  req.body = body_hash.to_json
  Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
end

def delete(uri)
  req = Net::HTTP::Delete.new(uri)
  req['Accept'] = 'application/json'
  Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
end

# ---------- Test Execution ----------
puts "Starting API test..."
puts

summary = []

# GET all books
uri = URI(BASE_URL)
response = get(uri)
summary << log_request("GET all books", response)

# CREATE a new book
create_body = { book: { title: "Test Book", author: "API Tester", isbn: "888888", published_date: Date.today.to_s } }
response = post(uri, create_body)
result = log_request("POST create book", response)
summary << result
created_book_id = result[:body]['id'] rescue nil

# UPDATE book
if created_book_id
  update_body = { book: { title: "Updated Test Book" } }
  uri_update = URI("#{BASE_URL}/#{created_book_id}")
  response = patch(uri_update, update_body)
  summary << log_request("PATCH update book", response)
end

# BORROW book
if created_book_id
  uri_borrow = URI("#{BASE_URL}/#{created_book_id}/borrow")
  response = post(uri_borrow, {})  # empty body
  summary << log_request("POST borrow book", response)
end

# SEARCH books
uri_search = URI("#{BASE_URL}/search?title=Test")
response = get(uri_search)
summary << log_request("GET search books (title includes 'Test')", response)

# SERIES AVAILABILITY
series_body = { book_ids: [created_book_id || 1, 2, 3], check_date: Date.today.to_s }
uri_series = URI("#{BASE_URL}/series_availability")
response = post(uri_series, series_body)
summary << log_request("POST series availability", response)

# DELETE book
if created_book_id
  uri_delete = URI("#{BASE_URL}/#{created_book_id}")
  response = delete(uri_delete)
  summary << log_request("DELETE book", response)
end

# ---------- Summary ----------
puts "\n" + "="*60
puts "API Test Summary:"
summary.each_with_index do |res, i|
  status = res[:success] ? "PASSED" : "FAILED"
  puts "#{i+1}. #{res[:action]} => #{status} (HTTP #{res[:status]})"
end
puts "="*60
puts "API test completed."
