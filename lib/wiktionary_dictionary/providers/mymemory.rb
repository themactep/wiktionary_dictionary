# frozen_string_literal: true

module WiktionaryDictionary
  module Providers
    # MyMemory API provider for translation services
    # API Documentation: https://mymemory.translated.net/doc/spec.php
    class Mymemory
      BASE_URL = "https://api.mymemory.translated.net"



      def initialize(client: nil)
        @client = client || WiktionaryDictionary::Client.new
      end

      # Translate a word and return multiple variants
      # @param word [String] The word to translate
      # @param source_lang [String] Source language (e.g., "russian")
      # @param target_lang [String] Target language (e.g., "english")
      # @return [Hash] Translation result with variants and contexts
      def translate(word, source_lang, target_lang)
        source_code = WiktionaryDictionary::LanguageMapper.normalize_language_code(source_lang)
        target_code = WiktionaryDictionary::LanguageMapper.normalize_language_code(target_lang)

        return error_response("Unsupported source language: #{source_lang}") unless source_code
        return error_response("Unsupported target language: #{target_lang}") unless target_code

        url = "#{BASE_URL}/get"
        params = {
          q: word,
          langpair: "#{source_code}|#{target_code}"
        }

        response = @client.get_request(url, params)

        if response[:ok]
          parse_translation_response(response[:data], word, source_lang, target_lang)
        else
          error_response("API request failed: #{response[:error]}")
        end
      rescue StandardError => e
        error_response("Unexpected error: #{e.message}")
      end

      private

      # Parse MyMemory API response and extract variants
      def parse_translation_response(data, word, source_lang, target_lang)
        return error_response("Invalid API response") unless data.is_a?(Hash)
        return error_response("API error: #{data['responseDetails']}") if data["responseStatus"] != 200

        variants = extract_variants(data)
        contexts = extract_contexts(data)

        {
          ok: true,
          word: word,
          source_lang: source_lang,
          target_lang: target_lang,
          variants: variants,
          contexts: contexts,
          providers_used: ["mymemory"],
          raw_response: data
        }
      end

      # Extract unique translation variants from API response
      def extract_variants(data)
        variants = []

        # Add main translation
        if data["responseData"] && data["responseData"]["translatedText"]
          main_translation = data["responseData"]["translatedText"].strip
          variants << main_translation unless main_translation.empty?
        end

        # Add alternative translations from matches
        if data["matches"] && data["matches"].is_a?(Array)
          data["matches"].each do |match|
            next unless match["translation"]

            translation = match["translation"].strip
            next if translation.empty?

            # Only add if not already present (case-insensitive)
            unless variants.any? { |v| v.downcase == translation.downcase }
              variants << translation
            end
          end
        end

        # Remove duplicates and sort by length (shorter translations first)
        variants.uniq.sort_by(&:length)
      end

      # Extract contextual examples from matches
      def extract_contexts(data)
        contexts = []

        return contexts unless data["matches"] && data["matches"].is_a?(Array)

        data["matches"].each do |match|
          next unless match["segment"] && match["translation"]

          # Skip if quality is too low (below 50)
          quality = match["quality"].to_i
          next if quality > 0 && quality < 50

          context = {
            source: match["segment"],
            target: match["translation"],
            quality: quality,
            usage_count: match["usage-count"].to_i,
            subject: match["subject"]
          }

          contexts << context
        end

        # Sort by quality and usage count
        contexts.sort_by { |c| [-c[:quality], -c[:usage_count]] }
      end

      # Create error response
      def error_response(message)
        {
          ok: false,
          error: message,
          provider: "mymemory"
        }
      end
    end
  end
end
