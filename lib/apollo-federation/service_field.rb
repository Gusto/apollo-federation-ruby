require 'graphql'
require 'apollo-federation/service'

module ApolloFederation
  module ServiceField
    extend GraphQL::Schema::Member::HasFields

    field(:_service, Service, null: false)

    def _service
      # TODO: Should `federation_sdl` be a class method or instance method?
      { sdl: context.schema.class.federation_sdl }
    end
  end
end
