# frozen_string_literal: true

require 'bundler/setup'
require 'wiktionary_dictionary'
require 'webmock/rspec'
require 'vcr'

# Configure VCR for API mocking
VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configure VCR to automatically use cassettes based on test names
  config.around(:each) do |example|
    if example.metadata[:vcr]
      name = example.metadata[:vcr].is_a?(String) ? example.metadata[:vcr] : example.full_description.gsub(/\s+/, '_').downcase
      VCR.use_cassette(name) { example.run }
    else
      example.run
    end
  end
end
