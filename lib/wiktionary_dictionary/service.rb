# frozen_string_literal: true

module WiktionaryDictionary
  # Main service class that coordinates multiple translation providers
  # Implements fallback chain pattern for reliability
  class Service
    # Default provider chain - order matters (most reliable first)
    DEFAULT_PROVIDERS = [
      WiktionaryDictionary::Providers::Mymemory
    ].freeze

    def initialize(providers: DEFAULT_PROVIDERS, client: nil)
      @providers = providers
      @client = client || WiktionaryDictionary::Client.new
    end

    # Get translation variants for a word using multiple providers
    # @param word [String] The word to translate
    # @param source_lang [String] Source language (e.g., "russian")
    # @param target_lang [String] Target language (e.g., "english")
    # @param options [Hash] Additional options
    # @return [Hash] Translation result with variants and contexts
    def get_translation_variants(word, source_lang, target_lang, options = {})
      return error_response("Word cannot be empty") if word.nil? || word.strip.empty?
      return error_response("Source language cannot be empty") if source_lang.nil? || source_lang.strip.empty?
      return error_response("Target language cannot be empty") if target_lang.nil? || target_lang.strip.empty?

      providers_tried = []
      last_error = nil

      @providers.each do |provider_class|
        begin
          provider = provider_class.new(client: @client)
          result = provider.translate(word, source_lang, target_lang)

          providers_tried << provider_class.name.split("::").last.downcase

          if result[:ok]
            # Enhance result with provider information
            result[:providers_tried] = providers_tried
            result[:total_providers] = @providers.length
            return result
          else
            last_error = result[:error]
          end
        rescue StandardError => e
          providers_tried << "#{provider_class.name.split("::").last.downcase}_error"
          last_error = "#{provider_class.name}: #{e.message}"
        end
      end

      # All providers failed
      {
        ok: false,
        error: "All providers failed",
        last_error: last_error,
        providers_tried: providers_tried,
        total_providers: @providers.length,
        word: word,
        source_lang: source_lang,
        target_lang: target_lang
      }
    end

    # Convenience method that matches the expected API from the handoff document
    alias translate get_translation_variants

    # Get available providers
    # @return [Array<String>] List of available provider names
    def available_providers
      @providers.map { |p| p.name.split("::").last.downcase }
    end

    # Check if a specific provider is available
    # @param provider_name [String] Name of the provider to check
    # @return [Boolean] True if provider is available
    def provider_available?(provider_name)
      available_providers.include?(provider_name.downcase)
    end

    # Get translation using a specific provider only
    # @param provider_name [String] Name of the provider to use
    # @param word [String] The word to translate
    # @param source_lang [String] Source language
    # @param target_lang [String] Target language
    # @return [Hash] Translation result
    def translate_with_provider(provider_name, word, source_lang, target_lang)
      provider_class = @providers.find do |p|
        p.name.split("::").last.downcase == provider_name.downcase
      end

      return error_response("Provider '#{provider_name}' not found") unless provider_class

      begin
        provider = provider_class.new(client: @client)
        result = provider.translate(word, source_lang, target_lang)
        result[:providers_tried] = [provider_name.downcase]
        result[:total_providers] = 1
        result
      rescue StandardError => e
        error_response("Provider error: #{e.message}")
      end
    end

    # Merge results from multiple providers (for future use)
    # @param results [Array<Hash>] Array of translation results
    # @return [Hash] Merged result
    def merge_results(results)
      successful_results = results.select { |r| r[:ok] }
      return results.first if successful_results.empty?

      merged_variants = []
      merged_contexts = []
      providers_used = []

      successful_results.each do |result|
        merged_variants.concat(result[:variants] || [])
        merged_contexts.concat(result[:contexts] || [])
        providers_used.concat(result[:providers_used] || [])
      end

      # Remove duplicates and sort
      merged_variants = merged_variants.uniq.sort_by(&:length)
      merged_contexts = merged_contexts.uniq { |c| [c[:source], c[:target]] }
                                     .sort_by { |c| [-c[:quality].to_i, -c[:usage_count].to_i] }

      first_result = successful_results.first
      {
        ok: true,
        word: first_result[:word],
        source_lang: first_result[:source_lang],
        target_lang: first_result[:target_lang],
        variants: merged_variants,
        contexts: merged_contexts,
        providers_used: providers_used.uniq,
        merged_from: successful_results.length
      }
    end

    private

    # Create error response
    def error_response(message)
      {
        ok: false,
        error: message,
        service: "wiktionary_dictionary"
      }
    end
  end
end
