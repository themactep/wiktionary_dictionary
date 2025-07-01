# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "timeout"

module WiktionaryDictionary
  # HTTP client for making API requests with proper headers and error handling
  class Client
    DEFAULT_TIMEOUT = 10
    DEFAULT_HEADERS = {
      "User-Agent" => "WiktionaryDictionary/#{WiktionaryDictionary::VERSION} (Ruby #{RUBY_VERSION})",
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }.freeze

    def initialize(timeout: DEFAULT_TIMEOUT, headers: {})
      @timeout = timeout
      @headers = DEFAULT_HEADERS.merge(headers)
    end

    # Make a GET request to the specified URL
    # @param url [String] The URL to request
    # @param params [Hash] Query parameters to append to the URL
    # @return [Hash] Response with :ok, :data, :error keys
    def get_request(url, params = {})
      uri = build_uri(url, params)

      begin
        response = make_http_request(uri, Net::HTTP::Get)
        parse_response(response)
      rescue Timeout::Error => e
        { ok: false, error: "Request timeout", details: e.message }
      rescue Net::HTTPError => e
        { ok: false, error: "HTTP error", details: e.message }
      rescue StandardError => e
        { ok: false, error: "Unexpected error", details: e.message }
      end
    end

    # Make a POST request to the specified URL
    # @param url [String] The URL to request
    # @param data [Hash] Data to send in the request body
    # @return [Hash] Response with :ok, :data, :error keys
    def post_request(url, data = {})
      uri = URI(url)

      begin
        response = make_http_request(uri, Net::HTTP::Post) do |request|
          request.body = data.to_json unless data.empty?
        end
        parse_response(response)
      rescue Timeout::Error => e
        { ok: false, error: "Request timeout", details: e.message }
      rescue Net::HTTPError => e
        { ok: false, error: "HTTP error", details: e.message }
      rescue StandardError => e
        { ok: false, error: "Unexpected error", details: e.message }
      end
    end

    private

    # Build URI with query parameters
    def build_uri(url, params)
      uri = URI(url)
      unless params.empty?
        query_string = params.map { |k, v| "#{URI.encode_www_form_component(k)}=#{URI.encode_www_form_component(v)}" }.join("&")
        uri.query = uri.query ? "#{uri.query}&#{query_string}" : query_string
      end
      uri
    end

    # Make HTTP request with proper configuration
    def make_http_request(uri, request_class)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.read_timeout = @timeout
        http.open_timeout = @timeout

        request = request_class.new(uri)
        @headers.each { |key, value| request[key] = value }

        yield(request) if block_given?

        http.request(request)
      end
    end

    # Parse HTTP response
    def parse_response(response)
      case response.code.to_i
      when 200..299
        begin
          data = response.body.empty? ? {} : JSON.parse(response.body)
          { ok: true, data: data, status: response.code.to_i }
        rescue JSON::ParserError => e
          { ok: false, error: "Invalid JSON response", details: e.message, raw_body: response.body }
        end
      when 400..499
        { ok: false, error: "Client error", status: response.code.to_i, details: response.message }
      when 500..599
        { ok: false, error: "Server error", status: response.code.to_i, details: response.message }
      else
        { ok: false, error: "Unexpected response", status: response.code.to_i, details: response.message }
      end
    end
  end
end
