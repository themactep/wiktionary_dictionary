# frozen_string_literal: true

module WiktionaryDictionary
  # Centralized language code mapping for all providers
  module LanguageMapper
    # Comprehensive language code mapping
    # Maps user-friendly language names to ISO 639-1 codes
    LANGUAGE_CODES = {
      # Major languages
      "english" => "en",
      "spanish" => "es",
      "french" => "fr",
      "german" => "de",
      "italian" => "it",
      "portuguese" => "pt",
      "russian" => "ru",
      "chinese" => "zh",
      "japanese" => "ja",
      "korean" => "ko",
      "arabic" => "ar",
      "hindi" => "hi",

      # European languages
      "dutch" => "nl",
      "swedish" => "sv",
      "norwegian" => "no",
      "danish" => "da",
      "finnish" => "fi",
      "polish" => "pl",
      "czech" => "cs",
      "slovak" => "sk",
      "hungarian" => "hu",
      "romanian" => "ro",
      "bulgarian" => "bg",
      "croatian" => "hr",
      "serbian" => "sr",
      "slovenian" => "sl",
      "estonian" => "et",
      "latvian" => "lv",
      "lithuanian" => "lt",
      "greek" => "el",
      "turkish" => "tr",

      # Other languages
      "hebrew" => "he",
      "thai" => "th",
      "vietnamese" => "vi",
      "indonesian" => "id",
      "malay" => "ms",
      "filipino" => "tl",
      "ukrainian" => "uk",
      "belarusian" => "be",
      "persian" => "fa",
      "urdu" => "ur",
      "bengali" => "bn",
      "tamil" => "ta",
      "telugu" => "te",
      "marathi" => "mr",
      "gujarati" => "gu",
      "kannada" => "kn",
      "malayalam" => "ml",
      "punjabi" => "pa",
      "nepali" => "ne",
      "sinhala" => "si",
      "burmese" => "my",
      "khmer" => "km",
      "lao" => "lo",
      "georgian" => "ka",
      "armenian" => "hy",
      "azerbaijani" => "az",
      "kazakh" => "kk",
      "kyrgyz" => "ky",
      "tajik" => "tg",
      "turkmen" => "tk",
      "uzbek" => "uz",
      "mongolian" => "mn",
      "tibetan" => "bo",
      "swahili" => "sw",
      "amharic" => "am",
      "yoruba" => "yo",
      "igbo" => "ig",
      "hausa" => "ha",
      "zulu" => "zu",
      "afrikaans" => "af",
      "xhosa" => "xh",
      "somali" => "so",
      "malagasy" => "mg",
      "esperanto" => "eo",
      "latin" => "la"
    }.freeze

    # Alternative names and aliases
    LANGUAGE_ALIASES = {
      # English variants
      "en" => "english",
      "eng" => "english",

      # Spanish variants
      "es" => "spanish",
      "spa" => "spanish",
      "castilian" => "spanish",

      # French variants
      "fr" => "french",
      "fra" => "french",
      "fre" => "french",

      # German variants
      "de" => "german",
      "deu" => "german",
      "ger" => "german",
      "deutsch" => "german",

      # Russian variants
      "ru" => "russian",
      "rus" => "russian",

      # Chinese variants
      "zh" => "chinese",
      "chi" => "chinese",
      "zho" => "chinese",
      "mandarin" => "chinese",
      "simplified chinese" => "chinese",
      "traditional chinese" => "chinese",

      # Portuguese variants
      "pt" => "portuguese",
      "por" => "portuguese",
      "brazilian" => "portuguese",
      "brazilian portuguese" => "portuguese",

      # Italian variants
      "it" => "italian",
      "ita" => "italian",

      # Japanese variants
      "ja" => "japanese",
      "jpn" => "japanese",

      # Korean variants
      "ko" => "korean",
      "kor" => "korean",

      # Arabic variants
      "ar" => "arabic",
      "ara" => "arabic",

      # Dutch variants
      "nl" => "dutch",
      "nld" => "dutch",
      "flemish" => "dutch"
    }.freeze

    module_function

    # Normalize language code from user input to standard ISO 639-1 code
    # @param language [String] Language name or code
    # @return [String, nil] Normalized language code or nil if not found
    def normalize_language_code(language)
      return nil if language.nil? || language.strip.empty?

      normalized_input = language.strip.downcase

      # Check if it's already a valid code
      return normalized_input if LANGUAGE_CODES.value?(normalized_input)

      # Check direct mapping
      return LANGUAGE_CODES[normalized_input] if LANGUAGE_CODES.key?(normalized_input)

      # Check aliases
      canonical_name = LANGUAGE_ALIASES[normalized_input]
      return LANGUAGE_CODES[canonical_name] if canonical_name

      # Not found
      nil
    end

    # Get the canonical language name from code or name
    # @param language [String] Language name or code
    # @return [String, nil] Canonical language name or nil if not found
    def canonical_language_name(language)
      return nil if language.nil? || language.strip.empty?

      normalized_input = language.strip.downcase

      # Check if it's already a canonical name
      return normalized_input if LANGUAGE_CODES.key?(normalized_input)

      # Check if it's a code
      canonical = LANGUAGE_CODES.key(normalized_input)
      return canonical if canonical

      # Check aliases
      return LANGUAGE_ALIASES[normalized_input] if LANGUAGE_ALIASES.key?(normalized_input)

      # Not found
      nil
    end

    # Check if a language is supported
    # @param language [String] Language name or code
    # @return [Boolean] True if language is supported
    def supported_language?(language)
      !normalize_language_code(language).nil?
    end

    # Get all supported languages
    # @return [Array<String>] List of supported language names
    def supported_languages
      LANGUAGE_CODES.keys.sort
    end

    # Get all supported language codes
    # @return [Array<String>] List of supported language codes
    def supported_language_codes
      LANGUAGE_CODES.values.uniq.sort
    end

    # Get language pairs (for debugging/info purposes)
    # @return [Hash] Hash of language names to codes
    def language_pairs
      LANGUAGE_CODES.dup
    end
  end
end
