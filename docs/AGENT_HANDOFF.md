# Agent Handoff Document - Wiktionary Dictionary Project

## PROJECT CONTEXT & HISTORY

### Previous Work Completed
- **Reverso Ruby Gem**: Complete implementation at `/home/paul/projects/reverso-ruby-gem/`
- **Status**: 129 tests, 87% passing, but APIs blocked by bot detection (403 Forbidden)
- **Only Working API**: Spell check (reliable)
- **Blocked APIs**: Context translation, synonyms, conjugation
- **Conclusion**: Reverso unsuitable for dictionary functionality due to anti-bot measures

### Current Project Goal
Build a **multi-variant translation service** for ambiguous words that provides:
- Multiple translation variants (e.g., Russian "лук" → English "bow", "onion", "look")
- Contextual examples showing usage
- Meaning disambiguation
- Production-ready Rails integration

## USER REQUIREMENTS

### Primary Use Case
```ruby
# User wants this functionality:
word = "лук" # Russian
variants = get_translation_variants(word, "russian", "english")
# Expected: ["bow", "onion", "look"] with contexts
```

### User Preferences
- Organize projects in separate workspaces by functionality
- Use i18n translation for static text
- Keep code minimal (embedded device constraints)
- No placeholders/dummy functions
- Write tests and ensure they pass
- Use pure C where possible (not applicable here)

## TECHNICAL STRATEGY

### Multi-Provider Approach (CRITICAL)
Since Reverso APIs are blocked, use multiple free APIs:

1. **Wiktionary API** (Primary)
   - URL: `https://en.wiktionary.org/api/rest_v1/`
   - Free, unlimited, reliable
   - Rich definitions and etymology

2. **MyMemory API** (Secondary)
   - URL: `https://api.mymemory.translated.net/`
   - Free 10k requests/day
   - Translation memory with contexts

3. **Linguee Scraping** (Tertiary)
   - URL: `https://www.linguee.com/`
   - Professional translation contexts
   - Requires proper User-Agent headers

### Architecture Pattern
```ruby
# Fallback chain implementation
PROVIDERS = [MyMemoryService, LingueeService, WiktionaryService]

def get_translation_variants(word, source, target)
  PROVIDERS.each do |provider|
    result = provider.translate(word, source, target)
    return result if result[:ok]
  end
  { ok: false, error: "All providers failed" }
end
```

## IMPLEMENTATION ROADMAP

### Phase 1: Foundation (START HERE)
1. **Initialize gem structure**
   ```bash
   bundle gem wiktionary_dictionary
   cd wiktionary_dictionary
   ```

2. **Create basic client**
   ```ruby
   # lib/wiktionary_dictionary/client.rb
   class Client
     def get_request(url)
       # HTTP client with proper headers
     end
   end
   ```

3. **Implement MyMemory provider first** (most reliable)
   ```ruby
   # lib/wiktionary_dictionary/providers/mymemory.rb
   class MymemoryProvider
     def translate(word, source_lang, target_lang)
       url = "https://api.mymemory.translated.net/get?q=#{word}&langpair=#{source_lang}|#{target_lang}"
       # Parse response for variants and contexts
     end
   end
   ```

### Phase 2: Core Functionality
1. **Add Wiktionary provider**
2. **Implement result merging**
3. **Add comprehensive tests**
4. **Basic caching**

### Phase 3: Production Features
1. **Linguee scraping**
2. **Rails integration**
3. **Background processing**
4. **Performance optimization**

## CRITICAL TECHNICAL DETAILS

### Language Code Mapping
```ruby
LANGUAGE_CODES = {
  'russian' => 'ru',
  'english' => 'en',
  'french' => 'fr',
  'german' => 'de',
  'spanish' => 'es'
}
```

### Expected Response Format
```ruby
{
  ok: true,
  word: "лук",
  source_lang: "russian",
  target_lang: "english",
  variants: ["bow", "onion", "look"],
  contexts: [
    {
      source: "стрелять из лука",
      target: "shoot with a bow",
      meaning: "weapon"
    },
    {
      source: "резать лук",
      target: "cut onions",
      meaning: "vegetable"
    }
  ],
  providers_used: ["mymemory", "wiktionary"]
}
```

### Error Handling Pattern
```ruby
begin
  result = provider.translate(word, source, target)
rescue Net::TimeoutError => e
  { ok: false, error: "timeout", provider: provider.class.name }
rescue => e
  { ok: false, error: e.message, provider: provider.class.name }
end
```

## TESTING STRATEGY

### Test Structure
```ruby
# spec/providers/mymemory_spec.rb
RSpec.describe MymemoryProvider do
  describe '#translate' do
    it 'returns multiple variants for ambiguous words' do
      VCR.use_cassette('mymemory_luk') do
        result = provider.translate('лук', 'russian', 'english')
        expect(result[:variants]).to include('bow', 'onion')
      end
    end
  end
end
```

### VCR Configuration
```ruby
# spec/spec_helper.rb
VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
end
```

## IMMEDIATE NEXT STEPS

1. **Run**: `bundle gem wiktionary_dictionary`
2. **Add dependencies**: `rspec`, `webmock`, `vcr`
3. **Create MyMemory provider** (start with this - most reliable)
4. **Write tests for Russian "лук" example**
5. **Implement basic client with proper headers**

## REFERENCE IMPLEMENTATIONS

### MyMemory API Example
```bash
curl "https://api.mymemory.translated.net/get?q=лук&langpair=ru|en"
```

### Wiktionary API Example
```bash
curl "https://en.wiktionary.org/api/rest_v1/page/definition/лук"
```

## SUCCESS CRITERIA

- [ ] Russian "лук" returns ["bow", "onion", "look"]
- [ ] Contextual examples for each variant
- [ ] 95%+ test coverage
- [ ] <500ms response time
- [ ] Handles API failures gracefully
- [ ] Rails integration ready

## PREVIOUS LESSONS LEARNED

1. **Bot detection is real** - Use proper User-Agent headers
2. **Multi-provider is essential** - Single APIs get blocked
3. **Caching is critical** - Reduces API dependency
4. **Error handling must be comprehensive** - APIs fail frequently
5. **Test with real examples** - "лук" is perfect test case

The agent in this workspace should focus on implementing a reliable multi-provider dictionary service, starting with MyMemory API as the foundation.

