# frozen_string_literal: true

require_relative "wiktionary_dictionary/version"
require_relative "wiktionary_dictionary/language_mapper"
require_relative "wiktionary_dictionary/client"
require_relative "wiktionary_dictionary/providers/mymemory"
require_relative "wiktionary_dictionary/service"

module WiktionaryDictionary
  class Error < StandardError; end

  # Convenience method for getting translation variants
  # @param word [String] The word to translate
  # @param source_lang [String] Source language (e.g., "russian")
  # @param target_lang [String] Target language (e.g., "english")
  # @return [Hash] Translation result with variants and contexts
  def self.get_translation_variants(word, source_lang, target_lang)
    service = Service.new
    service.get_translation_variants(word, source_lang, target_lang)
  end

  # Alias for compatibility with handoff document expectations
  class << self
    alias_method :translate, :get_translation_variants
  end
end
