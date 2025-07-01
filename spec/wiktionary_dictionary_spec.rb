# frozen_string_literal: true

require "spec_helper"

RSpec.describe WiktionaryDictionary do
  it "has a version number" do
    expect(WiktionaryDictionary::VERSION).not_to be nil
  end

  describe ".get_translation_variants" do
    it "provides convenient access to translation service", :vcr do
      result = WiktionaryDictionary.get_translation_variants("лук", "russian", "english")

      expect(result[:ok]).to be true
      expect(result[:word]).to eq("лук")
      expect(result[:variants]).to be_an(Array)
      expect(result[:variants]).not_to be_empty

      # Should include multiple variants for ambiguous word
      variants_lower = result[:variants].map(&:downcase)
      expect(variants_lower).to include("onion")
      expect(variants_lower).to include("bow")
    end
  end

  describe ".translate" do
    it "is an alias for get_translation_variants" do
      expect(WiktionaryDictionary.method(:translate)).to eq(WiktionaryDictionary.method(:get_translation_variants))
    end

    it "works as expected", :vcr do
      result = WiktionaryDictionary.translate("hello", "english", "french")

      expect(result[:ok]).to be true
      expect(result[:word]).to eq("hello")
      expect(result[:variants]).to be_an(Array)
    end
  end
end
