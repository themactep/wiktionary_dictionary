# frozen_string_literal: true

require_relative 'lib/wiktionary_dictionary/version'

Gem::Specification.new do |spec|
  spec.name = 'wiktionary_dictionary'
  spec.version = WiktionaryDictionary::VERSION
  spec.authors = ['Paul Philippov']
  spec.email = ['paul@themactep.com']

  spec.summary = 'Multi-variant translation service for ambiguous words'
  spec.description = 'A Ruby gem that provides multiple translation variants for ambiguous words using various translation APIs'
  spec.homepage = 'https://github.com/themactep/wiktionary-dictionary'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/themactep/wiktionary-dictionary'
  spec.metadata['changelog_uri'] = 'https://github.com/themactep/wiktionary-dictionary/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'net-http', '~> 0.3'
  spec.add_dependency 'json', '~> 2.6'

  # Development dependencies
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.add_development_dependency 'vcr', '~> 6.1'
  spec.add_development_dependency 'rake', '~> 13.0'
end
