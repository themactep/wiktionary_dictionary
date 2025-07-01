# frozen_string_literal: true

require "spec_helper"

RSpec.describe WiktionaryDictionary::Service do
  let(:service) { described_class.new }

  describe "#get_translation_variants" do
    context "with valid inputs" do
      it "returns translation variants for Russian 'лук'", :vcr do
        result = service.get_translation_variants("лук", "russian", "english")

        expect(result[:ok]).to be true
        expect(result[:word]).to eq("лук")
        expect(result[:source_lang]).to eq("russian")
        expect(result[:target_lang]).to eq("english")
        expect(result[:variants]).to be_an(Array)
        expect(result[:variants]).not_to be_empty
        expect(result[:providers_tried]).to include("mymemory")
        expect(result[:total_providers]).to eq(1)

        # Should include multiple variants for ambiguous word
        expect(result[:variants].length).to be > 1
        variants_lower = result[:variants].map(&:downcase)
        expect(variants_lower).to include("onion")
        expect(variants_lower).to include("bow")
      end

      it "includes contextual information" do
        VCR.use_cassette("service_luk_with_contexts") do
          result = service.get_translation_variants("лук", "russian", "english")

          expect(result[:ok]).to be true
          expect(result[:contexts]).to be_an(Array)
        end
      end
    end

    context "with invalid inputs" do
      it "handles empty word" do
        result = service.get_translation_variants("", "russian", "english")

        expect(result[:ok]).to be false
        expect(result[:error]).to eq("Word cannot be empty")
      end

      it "handles nil word" do
        result = service.get_translation_variants(nil, "russian", "english")

        expect(result[:ok]).to be false
        expect(result[:error]).to eq("Word cannot be empty")
      end

      it "handles empty source language" do
        result = service.get_translation_variants("test", "", "english")

        expect(result[:ok]).to be false
        expect(result[:error]).to eq("Source language cannot be empty")
      end

      it "handles empty target language" do
        result = service.get_translation_variants("test", "russian", "")

        expect(result[:ok]).to be false
        expect(result[:error]).to eq("Target language cannot be empty")
      end
    end

    context "with provider failures" do
      it "handles all providers failing" do
        # Mock a failing provider
        failing_provider = class_double("FailingProvider")
        allow(failing_provider).to receive(:new).and_return(
          instance_double("provider", translate: { ok: false, error: "API error" })
        )
        allow(failing_provider).to receive(:name).and_return("WiktionaryDictionary::Providers::Failing")

        service = described_class.new(providers: [failing_provider])
        result = service.get_translation_variants("test", "russian", "english")

        expect(result[:ok]).to be false
        expect(result[:error]).to eq("All providers failed")
        expect(result[:last_error]).to eq("API error")
        expect(result[:providers_tried]).to include("failing")
      end

      it "handles provider exceptions" do
        # Mock a provider that raises an exception
        error_provider = class_double("ErrorProvider")
        allow(error_provider).to receive(:new).and_raise(StandardError.new("Connection failed"))
        allow(error_provider).to receive(:name).and_return("WiktionaryDictionary::Providers::Error")

        service = described_class.new(providers: [error_provider])
        result = service.get_translation_variants("test", "russian", "english")

        expect(result[:ok]).to be false
        expect(result[:error]).to eq("All providers failed")
        expect(result[:providers_tried]).to include("error_error")
      end
    end
  end

  describe "#translate" do
    it "is an alias for get_translation_variants" do
      expect(service.method(:translate)).to eq(service.method(:get_translation_variants))
    end
  end

  describe "#available_providers" do
    it "returns list of available providers" do
      providers = service.available_providers
      expect(providers).to be_an(Array)
      expect(providers).to include("mymemory")
    end
  end

  describe "#provider_available?" do
    it "returns true for available providers" do
      expect(service.provider_available?("mymemory")).to be true
      expect(service.provider_available?("MyMemory")).to be true # case insensitive
    end

    it "returns false for unavailable providers" do
      expect(service.provider_available?("nonexistent")).to be false
    end
  end

  describe "#translate_with_provider" do
    it "uses specific provider", :vcr do
      result = service.translate_with_provider("mymemory", "hello", "english", "french")

      expect(result[:providers_tried]).to eq(["mymemory"])
      expect(result[:total_providers]).to eq(1)
    end

    it "handles unknown provider" do
      result = service.translate_with_provider("unknown", "hello", "english", "french")

      expect(result[:ok]).to be false
      expect(result[:error]).to include("Provider 'unknown' not found")
    end
  end

  describe "#merge_results" do
    it "merges successful results" do
      results = [
        {
          ok: true,
          word: "test",
          source_lang: "en",
          target_lang: "fr",
          variants: ["test1", "test2"],
          contexts: [{ source: "test", target: "test1", quality: 80, usage_count: 5 }],
          providers_used: ["provider1"]
        },
        {
          ok: true,
          word: "test",
          source_lang: "en",
          target_lang: "fr",
          variants: ["test2", "test3"],
          contexts: [{ source: "test", target: "test3", quality: 90, usage_count: 3 }],
          providers_used: ["provider2"]
        }
      ]

      merged = service.merge_results(results)

      expect(merged[:ok]).to be true
      expect(merged[:variants]).to eq(["test1", "test2", "test3"])
      expect(merged[:contexts].length).to eq(2)
      expect(merged[:providers_used]).to eq(["provider1", "provider2"])
      expect(merged[:merged_from]).to eq(2)
    end

    it "handles no successful results" do
      results = [
        { ok: false, error: "error1" },
        { ok: false, error: "error2" }
      ]

      merged = service.merge_results(results)
      expect(merged[:ok]).to be false
    end
  end
end
