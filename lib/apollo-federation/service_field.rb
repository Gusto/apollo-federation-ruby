# frozen_string_literal: true

require 'graphql'
require 'apollo-federation/service'

module ApolloFederation
  module ServiceField
    extend GraphQL::Schema::Member::HasFields

    field(:_service, Service, null: false)

    def _service
      { sdl: context.schema.class.federation_sdl }
    end
  end
end
