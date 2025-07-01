# frozen_string_literal: true

require "spec_helper"

RSpec.describe WiktionaryDictionary::Client do
  let(:client) { described_class.new }

  describe "#get_request" do
    it "makes a successful GET request", :vcr do
      # Test with a simple API endpoint
      result = client.get_request("https://httpbin.org/get", { test: "value" })

      expect(result[:ok]).to be true
      expect(result[:data]).to be_a(Hash)
      expect(result[:status]).to eq(200)
    end

    it "handles timeout errors" do
      allow(Net::HTTP).to receive(:start).and_raise(Timeout::Error.new("timeout"))

      result = client.get_request("https://example.com")

      expect(result[:ok]).to be false
      expect(result[:error]).to eq("Request timeout")
    end

    it "handles HTTP errors" do
      stub_request(:get, "https://example.com/404")
        .to_return(status: 404, body: "Not Found")

      result = client.get_request("https://example.com/404")

      expect(result[:ok]).to be false
      expect(result[:error]).to eq("Client error")
      expect(result[:status]).to eq(404)
    end

    it "handles invalid JSON responses" do
      stub_request(:get, "https://example.com/invalid")
        .to_return(status: 200, body: "invalid json")

      result = client.get_request("https://example.com/invalid")

      expect(result[:ok]).to be false
      expect(result[:error]).to eq("Invalid JSON response")
    end
  end

  describe "#post_request" do
    it "makes a successful POST request", :vcr do
      result = client.post_request("https://httpbin.org/post", { key: "value" })

      expect(result[:ok]).to be true
      expect(result[:data]).to be_a(Hash)
      expect(result[:status]).to eq(200)
    end
  end

  describe "initialization" do
    it "uses default timeout" do
      client = described_class.new
      expect(client.instance_variable_get(:@timeout)).to eq(10)
    end

    it "accepts custom timeout" do
      client = described_class.new(timeout: 30)
      expect(client.instance_variable_get(:@timeout)).to eq(30)
    end

    it "merges custom headers with defaults" do
      custom_headers = { "Custom-Header" => "value" }
      client = described_class.new(headers: custom_headers)
      headers = client.instance_variable_get(:@headers)

      expect(headers["Custom-Header"]).to eq("value")
      expect(headers["User-Agent"]).to include("WiktionaryDictionary")
    end
  end
end
