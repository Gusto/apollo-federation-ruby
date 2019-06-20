
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "apollo-federation/version"

Gem::Specification.new do |spec|
  spec.name          = "apollo-federation"
  spec.version       = ApolloFederation::VERSION
  spec.authors       = ["Gusto"]

  spec.summary       = 'This gem extends the graphql gem to add support for creating a federated schema'
  spec.description   = spec.summary
  spec.homepage      = 'https://www.gusto.com'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://gemstash.zp-int.com/private'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.add_dependency 'graphql'

  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rack'
  spec.add_development_dependency 'rspec'
end
