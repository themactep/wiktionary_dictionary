# RAILS INTEGRATION GUIDE - WiktionaryDictionary Gem

## AGENT CONTEXT
- Gem: `wiktionary_dictionary` - Multi-variant translation service
- Primary use case: Ambiguous word translation (e.g., Russian "лук" → ["bow", "onion", "allium"])
- Architecture: Multi-provider fallback chain (MyMemory API primary)
- Status: Production-ready, 62 tests passing, VCR cassettes included

## CRITICAL API KNOWLEDGE

### Core Method
```ruby
result = WiktionaryDictionary.get_translation_variants(word, source_lang, target_lang)
# Alias: WiktionaryDictionary.translate(word, source_lang, target_lang)
```

### Response Format
```ruby
{
  ok: true/false,
  word: "лук",
  source_lang: "russian",
  target_lang: "english",
  variants: ["Bow", "onion", "Allium"],
  contexts: [
    { source: "Лук", target: "Bow", quality: 74, usage_count: 8, subject: "All" }
  ],
  providers_used: ["mymemory"],
  error: "error_message" # only if ok: false
}
```

### Language Support
- 76+ languages supported
- Input normalization: "russian"/"ru"/"Russian"/"RU" all work
- Aliases: "mandarin"→"zh", "castilian"→"es", "deutsch"→"de"

## RAILS INTEGRATION PATTERNS

### 1. GEMFILE SETUP
```ruby
# Gemfile
gem 'wiktionary_dictionary'
# Dependencies auto-included: net-http, json, rspec, webmock, vcr
```

### 2. SERVICE OBJECT PATTERN (RECOMMENDED)
```ruby
# app/services/translation_service.rb
class TranslationService
  def self.get_variants(word, source_lang, target_lang)
    result = WiktionaryDictionary.get_translation_variants(word, source_lang, target_lang)

    if result[:ok]
      {
        success: true,
        word: result[:word],
        variants: result[:variants],
        contexts: result[:contexts],
        metadata: {
          providers: result[:providers_used],
          source_lang: result[:source_lang],
          target_lang: result[:target_lang]
        }
      }
    else
      {
        success: false,
        error: result[:error],
        word: word,
        source_lang: source_lang,
        target_lang: target_lang
      }
    end
  end
end
```

### 3. CONTROLLER INTEGRATION
```ruby
# app/controllers/translations_controller.rb
class TranslationsController < ApplicationController
  def create
    @result = TranslationService.get_variants(
      params[:word],
      params[:source_language],
      params[:target_language]
    )

    if @result[:success]
      render json: @result, status: :ok
    else
      render json: { error: @result[:error] }, status: :unprocessable_entity
    end
  end
end
```

### 4. MODEL INTEGRATION (WITH CACHING)
```ruby
# app/models/translation.rb
class Translation < ApplicationRecord
  validates :word, :source_lang, :target_lang, presence: true

  def self.find_or_fetch(word, source_lang, target_lang)
    cache_key = "translation:#{word}:#{source_lang}:#{target_lang}"

    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      result = WiktionaryDictionary.get_translation_variants(word, source_lang, target_lang)

      if result[:ok]
        create!(
          word: word,
          source_lang: source_lang,
          target_lang: target_lang,
          variants: result[:variants],
          contexts: result[:contexts],
          providers_used: result[:providers_used]
        )
      else
        nil
      end
    end
  end
end
```

### 5. BACKGROUND JOB PATTERN
```ruby
# app/jobs/translation_job.rb
class TranslationJob < ApplicationJob
  queue_as :default

  def perform(word, source_lang, target_lang, user_id)
    result = WiktionaryDictionary.get_translation_variants(word, source_lang, target_lang)

    if result[:ok]
      # Store result
      Translation.create!(
        word: word,
        source_lang: source_lang,
        target_lang: target_lang,
        variants: result[:variants],
        contexts: result[:contexts],
        user_id: user_id
      )

      # Notify user via ActionCable/email/etc
      TranslationChannel.broadcast_to(
        User.find(user_id),
        { type: 'translation_complete', data: result }
      )
    else
      # Handle error
      Rails.logger.error "Translation failed: #{result[:error]}"
    end
  end
end
```

## DATABASE SCHEMA RECOMMENDATIONS

### Migration
```ruby
# db/migrate/xxx_create_translations.rb
class CreateTranslations < ActiveRecord::Migration[7.0]
  def change
    create_table :translations do |t|
      t.string :word, null: false
      t.string :source_lang, null: false
      t.string :target_lang, null: false
      t.json :variants, null: false, default: []
      t.json :contexts, null: false, default: []
      t.json :providers_used, null: false, default: []
      t.integer :quality_score
      t.references :user, foreign_key: true
      t.timestamps
    end

    add_index :translations, [:word, :source_lang, :target_lang], unique: true
    add_index :translations, :created_at
  end
end
```

## ERROR HANDLING PATTERNS

### Comprehensive Error Handler
```ruby
# app/services/translation_error_handler.rb
class TranslationErrorHandler
  RETRY_ERRORS = ['Request timeout', 'API request failed'].freeze

  def self.handle_with_retry(word, source_lang, target_lang, max_retries: 3)
    retries = 0

    begin
      result = WiktionaryDictionary.get_translation_variants(word, source_lang, target_lang)

      if result[:ok]
        result
      elsif RETRY_ERRORS.any? { |error| result[:error].include?(error) } && retries < max_retries
        retries += 1
        sleep(2 ** retries) # Exponential backoff
        retry
      else
        {
          success: false,
          error: result[:error],
          retries_attempted: retries,
          fallback_suggestions: generate_fallback(word, source_lang, target_lang)
        }
      end
    rescue StandardError => e
      Rails.logger.error "Translation service error: #{e.message}"
      { success: false, error: "Service unavailable", exception: e.message }
    end
  end

  private

  def self.generate_fallback(word, source_lang, target_lang)
    # Simple fallback logic
    ["#{word} (#{source_lang} → #{target_lang})", "Translation unavailable"]
  end
end
```

## TESTING PATTERNS

### RSpec Integration
```ruby
# spec/services/translation_service_spec.rb
require 'rails_helper'

RSpec.describe TranslationService do
  describe '.get_variants' do
    it 'returns formatted result for successful translation', :vcr do
      result = described_class.get_variants('лук', 'russian', 'english')

      expect(result[:success]).to be true
      expect(result[:variants]).to include('onion', 'Bow')
      expect(result[:metadata][:providers]).to include('mymemory')
    end

    it 'handles API failures gracefully' do
      allow(WiktionaryDictionary).to receive(:get_translation_variants)
        .and_return({ ok: false, error: 'API error' })

      result = described_class.get_variants('test', 'english', 'french')

      expect(result[:success]).to be false
      expect(result[:error]).to eq('API error')
    end
  end
end
```

### VCR Configuration
```ruby
# spec/support/vcr.rb
VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<API_KEY>') { ENV['TRANSLATION_API_KEY'] }
end
```

## PERFORMANCE OPTIMIZATION

### Caching Strategy
```ruby
# config/application.rb
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }

# Usage in service
class TranslationService
  CACHE_TTL = 24.hours

  def self.get_variants_cached(word, source_lang, target_lang)
    cache_key = "translation:#{Digest::MD5.hexdigest("#{word}:#{source_lang}:#{target_lang}")}"

    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      get_variants(word, source_lang, target_lang)
    end
  end
end
```

### Rate Limiting
```ruby
# app/controllers/concerns/rate_limitable.rb
module RateLimitable
  extend ActiveSupport::Concern

  def check_translation_rate_limit
    key = "translation_rate_limit:#{request.ip}"
    count = Rails.cache.read(key) || 0

    if count >= 100 # 100 requests per hour
      render json: { error: 'Rate limit exceeded' }, status: :too_many_requests
      return false
    end

    Rails.cache.write(key, count + 1, expires_in: 1.hour)
    true
  end
end
```

## CONFIGURATION

### Environment Variables
```ruby
# config/initializers/translation.rb
TRANSLATION_CONFIG = {
  cache_ttl: ENV.fetch('TRANSLATION_CACHE_TTL', 24.hours),
  rate_limit: ENV.fetch('TRANSLATION_RATE_LIMIT', 100),
  timeout: ENV.fetch('TRANSLATION_TIMEOUT', 10),
  retry_attempts: ENV.fetch('TRANSLATION_RETRY_ATTEMPTS', 3)
}.freeze
```

## API ENDPOINTS DESIGN

### RESTful Routes
```ruby
# config/routes.rb
resources :translations, only: [:create, :show, :index] do
  collection do
    post :batch # For multiple translations
    get :languages # Supported languages
  end
end

# app/controllers/translations_controller.rb
def languages
  render json: {
    supported: WiktionaryDictionary::LanguageMapper.supported_languages,
    codes: WiktionaryDictionary::LanguageMapper.supported_language_codes
  }
end

def batch
  results = params[:translations].map do |translation|
    TranslationService.get_variants(
      translation[:word],
      translation[:source_lang],
      translation[:target_lang]
    )
  end

  render json: { translations: results }
end
```

## MONITORING & LOGGING

### Custom Logger
```ruby
# app/services/translation_logger.rb
class TranslationLogger
  def self.log_translation(word, source_lang, target_lang, result, duration)
    Rails.logger.info({
      event: 'translation_request',
      word: word,
      source_lang: source_lang,
      target_lang: target_lang,
      success: result[:ok] || result[:success],
      variants_count: result[:variants]&.length || 0,
      providers_used: result[:providers_used] || [],
      duration_ms: duration,
      timestamp: Time.current.iso8601
    }.to_json)
  end
end
```

## DEPLOYMENT CONSIDERATIONS

### Docker Integration
```dockerfile
# Add to Dockerfile
RUN bundle config set --local without 'development test'
RUN bundle install

# Ensure network access for API calls
EXPOSE 3000
```

### Health Check
```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  def translation_service
    result = WiktionaryDictionary.get_translation_variants('test', 'english', 'french')

    if result[:ok]
      render json: { status: 'healthy', service: 'translation' }
    else
      render json: { status: 'unhealthy', error: result[:error] }, status: :service_unavailable
    end
  end
end
```

## CRITICAL IMPLEMENTATION NOTES

1. **Always check result[:ok]** before accessing variants/contexts
2. **Use caching** - API calls are ~3-4 seconds, cache hits ~40ms
3. **Handle network failures** - MyMemory API can timeout
4. **Language normalization** - Use exact strings from LanguageMapper
5. **VCR cassettes included** - Tests run without network calls
6. **Rate limiting** - MyMemory has 10k requests/day limit
7. **Error logging** - Log all API failures for monitoring
8. **Background processing** - Use jobs for bulk translations

## QUICK START CHECKLIST

- [ ] Add gem to Gemfile
- [ ] Create TranslationService class
- [ ] Add caching layer (Redis recommended)
- [ ] Implement error handling with retries
- [ ] Add rate limiting
- [ ] Create database migration if storing results
- [ ] Add VCR cassettes to test suite
- [ ] Configure monitoring/logging
- [ ] Test with Russian "лук" example
- [ ] Deploy with health checks

This guide provides complete Rails integration patterns for the WiktionaryDictionary gem with production-ready error handling, caching, and monitoring.
