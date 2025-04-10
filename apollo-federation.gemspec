# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'apollo-federation/version'

Gem::Specification.new do |spec|
  spec.name          = 'apollo-federation'
  spec.version       = ApolloFederation::VERSION
  spec.authors       = ['Noa Elad', 'Rylan Collins']
  spec.email         = ['noa.elad@gusto.com', 'rylan@gusto.com']

  spec.summary       = 'A Ruby implementation of Apollo Federation'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/Gusto/apollo-federation-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.2.0' # bc of `.to_sym`

  spec.metadata    = {
    'homepage_uri' => 'https://github.com/Gusto/apollo-federation-ruby',
    'changelog_uri' => 'https://github.com/Gusto/apollo-federation-ruby/releases',
    'source_code_uri' => 'https://github.com/Gusto/apollo-federation-ruby',
    'bug_tracker_uri' => 'https://github.com/Gusto/apollo-federation-ruby/issues',
  }

  spec.files = `git ls-files bin lib *.md LICENSE`.split("\n")

  spec.add_dependency 'graphql'

  spec.add_runtime_dependency 'google-protobuf', '< 5'

  spec.add_development_dependency 'actionpack'
  spec.add_development_dependency 'debug'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rack', '~> 2.0'
  spec.add_development_dependency 'rackup'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop', '~> 0.75.0'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'webrick'

  # TODO: 3.4 need to explicit add mutex_m and ostruct
  spec.add_development_dependency 'mutex_m'
  spec.add_development_dependency 'ostruct'
end
