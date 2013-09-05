VCR.configure do |c|
  c.cassette_library_dir = Rails.root + 'spec/vcr_cassettes'
  c.hook_into :webmock 
  c.default_cassette_options = {
    :match_requests_on  => [:method, :uri, :body],
    :record             => :new_episodes 
  }
  c.allow_http_connections_when_no_cassette = true
end
