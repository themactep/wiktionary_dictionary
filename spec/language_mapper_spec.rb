# frozen_string_literal: true

require "spec_helper"

RSpec.describe WiktionaryDictionary::LanguageMapper do
  describe ".normalize_language_code" do
    context "with language names" do
      it "maps common language names to codes" do
        expect(described_class.normalize_language_code("russian")).to eq("ru")
        expect(described_class.normalize_language_code("english")).to eq("en")
        expect(described_class.normalize_language_code("french")).to eq("fr")
        expect(described_class.normalize_language_code("german")).to eq("de")
        expect(described_class.normalize_language_code("spanish")).to eq("es")
        expect(described_class.normalize_language_code("chinese")).to eq("zh")
        expect(described_class.normalize_language_code("japanese")).to eq("ja")
        expect(described_class.normalize_language_code("korean")).to eq("ko")
      end

      it "handles case insensitive input" do
        expect(described_class.normalize_language_code("RUSSIAN")).to eq("ru")
        expect(described_class.normalize_language_code("English")).to eq("en")
        expect(described_class.normalize_language_code("FrEnCh")).to eq("fr")
      end

      it "handles whitespace" do
        expect(described_class.normalize_language_code(" russian ")).to eq("ru")
        expect(described_class.normalize_language_code("\tenglish\n")).to eq("en")
      end
    end

    context "with language codes" do
      it "passes through valid language codes" do
        expect(described_class.normalize_language_code("ru")).to eq("ru")
        expect(described_class.normalize_language_code("en")).to eq("en")
        expect(described_class.normalize_language_code("fr")).to eq("fr")
        expect(described_class.normalize_language_code("de")).to eq("de")
      end

      it "handles uppercase codes" do
        expect(described_class.normalize_language_code("RU")).to eq("ru")
        expect(described_class.normalize_language_code("EN")).to eq("en")
      end
    end

    context "with aliases" do
      it "maps language aliases" do
        expect(described_class.normalize_language_code("mandarin")).to eq("zh")
        expect(described_class.normalize_language_code("castilian")).to eq("es")
        expect(described_class.normalize_language_code("deutsch")).to eq("de")
        expect(described_class.normalize_language_code("brazilian")).to eq("pt")
        expect(described_class.normalize_language_code("flemish")).to eq("nl")
      end

      it "maps ISO 639-2 codes" do
        expect(described_class.normalize_language_code("eng")).to eq("en")
        expect(described_class.normalize_language_code("rus")).to eq("ru")
        expect(described_class.normalize_language_code("fra")).to eq("fr")
        expect(described_class.normalize_language_code("deu")).to eq("de")
      end
    end

    context "with invalid input" do
      it "returns nil for unsupported languages" do
        expect(described_class.normalize_language_code("klingon")).to be_nil
        expect(described_class.normalize_language_code("elvish")).to be_nil
        expect(described_class.normalize_language_code("nonexistent")).to be_nil
      end

      it "returns nil for empty input" do
        expect(described_class.normalize_language_code("")).to be_nil
        expect(described_class.normalize_language_code("   ")).to be_nil
        expect(described_class.normalize_language_code(nil)).to be_nil
      end
    end
  end

  describe ".canonical_language_name" do
    it "returns canonical names for language names" do
      expect(described_class.canonical_language_name("russian")).to eq("russian")
      expect(described_class.canonical_language_name("english")).to eq("english")
    end

    it "returns canonical names for language codes" do
      expect(described_class.canonical_language_name("ru")).to eq("russian")
      expect(described_class.canonical_language_name("en")).to eq("english")
      expect(described_class.canonical_language_name("fr")).to eq("french")
    end

    it "returns canonical names for aliases" do
      expect(described_class.canonical_language_name("mandarin")).to eq("chinese")
      expect(described_class.canonical_language_name("castilian")).to eq("spanish")
      expect(described_class.canonical_language_name("deutsch")).to eq("german")
    end

    it "handles case insensitive input" do
      expect(described_class.canonical_language_name("RUSSIAN")).to eq("russian")
      expect(described_class.canonical_language_name("RU")).to eq("russian")
    end

    it "returns nil for unsupported languages" do
      expect(described_class.canonical_language_name("klingon")).to be_nil
      expect(described_class.canonical_language_name("")).to be_nil
      expect(described_class.canonical_language_name(nil)).to be_nil
    end
  end

  describe ".supported_language?" do
    it "returns true for supported languages" do
      expect(described_class.supported_language?("russian")).to be true
      expect(described_class.supported_language?("ru")).to be true
      expect(described_class.supported_language?("mandarin")).to be true
      expect(described_class.supported_language?("eng")).to be true
    end

    it "returns false for unsupported languages" do
      expect(described_class.supported_language?("klingon")).to be false
      expect(described_class.supported_language?("")).to be false
      expect(described_class.supported_language?(nil)).to be false
    end
  end

  describe ".supported_languages" do
    it "returns array of supported language names" do
      languages = described_class.supported_languages
      expect(languages).to be_an(Array)
      expect(languages).to include("russian", "english", "french", "german", "spanish")
      expect(languages).to eq(languages.sort)
    end

    it "includes comprehensive language list" do
      languages = described_class.supported_languages
      expect(languages.length).to be > 50 # Should have many languages
      expect(languages).to include("chinese", "japanese", "korean", "arabic", "hindi")
      expect(languages).to include("dutch", "swedish", "norwegian", "danish", "finnish")
    end
  end

  describe ".supported_language_codes" do
    it "returns array of supported language codes" do
      codes = described_class.supported_language_codes
      expect(codes).to be_an(Array)
      expect(codes).to include("ru", "en", "fr", "de", "es")
      expect(codes).to eq(codes.sort)
    end

    it "contains unique codes only" do
      codes = described_class.supported_language_codes
      expect(codes.uniq).to eq(codes)
    end
  end

  describe ".language_pairs" do
    it "returns hash of language names to codes" do
      pairs = described_class.language_pairs
      expect(pairs).to be_a(Hash)
      expect(pairs["russian"]).to eq("ru")
      expect(pairs["english"]).to eq("en")
      expect(pairs["french"]).to eq("fr")
    end

    it "returns a copy of the internal mapping" do
      pairs1 = described_class.language_pairs
      pairs2 = described_class.language_pairs
      expect(pairs1).not_to be(pairs2) # Different objects
      expect(pairs1).to eq(pairs2) # Same content
    end
  end

  describe "comprehensive language support" do
    it "supports major world languages" do
      major_languages = %w[
        english spanish french german italian portuguese russian
        chinese japanese korean arabic hindi dutch swedish norwegian
        danish finnish polish czech hungarian romanian bulgarian
        turkish greek hebrew thai vietnamese indonesian
      ]

      major_languages.each do |lang|
        expect(described_class.supported_language?(lang)).to be(true), "#{lang} should be supported"
      end
    end

    it "maps all languages to valid ISO 639-1 codes" do
      described_class.supported_languages.each do |lang|
        code = described_class.normalize_language_code(lang)
        expect(code).to match(/\A[a-z]{2}\z/), "#{lang} should map to valid 2-letter code, got: #{code}"
      end
    end
  end
end
