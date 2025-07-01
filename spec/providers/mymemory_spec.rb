# frozen_string_literal: true

require "spec_helper"

RSpec.describe WiktionaryDictionary::Providers::Mymemory do
  let(:provider) { described_class.new }

  describe "#translate" do
    context "with Russian 'лук' to English" do
      it "returns multiple variants including bow and onion", :vcr do
        result = provider.translate("лук", "russian", "english")

        expect(result[:ok]).to be true
        expect(result[:word]).to eq("лук")
        expect(result[:source_lang]).to eq("russian")
        expect(result[:target_lang]).to eq("english")
        expect(result[:variants]).to be_an(Array)
        expect(result[:variants]).not_to be_empty

        # Check that we get multiple variants for this ambiguous word
        expect(result[:variants].length).to be > 1

        # Convert to lowercase for case-insensitive comparison
        variants_lower = result[:variants].map(&:downcase)

        # Should include common translations for лук
        expect(variants_lower).to include("onion")
        expect(variants_lower).to include("bow")

        expect(result[:contexts]).to be_an(Array)
        expect(result[:providers_used]).to eq(["mymemory"])
      end

      it "includes contextual information" do
        VCR.use_cassette("mymemory_luk_contexts") do
          result = provider.translate("лук", "russian", "english")

          expect(result[:ok]).to be true
          expect(result[:contexts]).to be_an(Array)

          unless result[:contexts].empty?
            context = result[:contexts].first
            expect(context).to have_key(:source)
            expect(context).to have_key(:target)
            expect(context).to have_key(:quality)
            expect(context).to have_key(:usage_count)
          end
        end
      end
    end

    context "with language code normalization" do
      it "accepts full language names" do
        VCR.use_cassette("mymemory_language_names") do
          result = provider.translate("hello", "english", "french")
          expect(result[:ok]).to be true
        end
      end

      it "accepts language codes" do
        VCR.use_cassette("mymemory_language_codes") do
          result = provider.translate("hello", "en", "fr")
          expect(result[:ok]).to be true
        end
      end

      it "handles unsupported languages" do
        result = provider.translate("hello", "klingon", "english")

        expect(result[:ok]).to be false
        expect(result[:error]).to include("Unsupported source language")
        expect(result[:provider]).to eq("mymemory")
      end
    end

    context "with API errors" do
      it "handles network timeouts" do
        client = instance_double(WiktionaryDictionary::Client)
        allow(client).to receive(:get_request).and_return({
          ok: false,
          error: "Request timeout"
        })

        provider = described_class.new(client: client)
        result = provider.translate("test", "english", "french")

        expect(result[:ok]).to be false
        expect(result[:error]).to include("API request failed")
      end

      it "handles invalid API responses" do
        client = instance_double(WiktionaryDictionary::Client)
        allow(client).to receive(:get_request).and_return({
          ok: true,
          data: "invalid response"
        })

        provider = described_class.new(client: client)
        result = provider.translate("test", "english", "french")

        expect(result[:ok]).to be false
        expect(result[:error]).to include("Invalid API response")
      end

      it "handles API error responses" do
        client = instance_double(WiktionaryDictionary::Client)
        allow(client).to receive(:get_request).and_return({
          ok: true,
          data: {
            "responseStatus" => 400,
            "responseDetails" => "Bad request"
          }
        })

        provider = described_class.new(client: client)
        result = provider.translate("test", "english", "french")

        expect(result[:ok]).to be false
        expect(result[:error]).to include("API error: Bad request")
      end
    end

    context "with edge cases" do
      it "handles empty translations" do
        client = instance_double(WiktionaryDictionary::Client)
        allow(client).to receive(:get_request).and_return({
          ok: true,
          data: {
            "responseStatus" => 200,
            "responseData" => { "translatedText" => "" },
            "matches" => []
          }
        })

        provider = described_class.new(client: client)
        result = provider.translate("test", "english", "french")

        expect(result[:ok]).to be true
        expect(result[:variants]).to be_empty
      end

      it "filters low quality matches" do
        client = instance_double(WiktionaryDictionary::Client)
        allow(client).to receive(:get_request).and_return({
          ok: true,
          data: {
            "responseStatus" => 200,
            "responseData" => { "translatedText" => "good" },
            "matches" => [
              {
                "segment" => "test",
                "translation" => "low quality",
                "quality" => "30"
              },
              {
                "segment" => "test",
                "translation" => "high quality",
                "quality" => "80"
              }
            ]
          }
        })

        provider = described_class.new(client: client)
        result = provider.translate("test", "english", "french")

        expect(result[:ok]).to be true
        expect(result[:contexts].length).to eq(1)
        expect(result[:contexts].first[:target]).to eq("high quality")
      end
    end
  end


end
