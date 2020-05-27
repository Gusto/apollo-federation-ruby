# frozen_string_literal: true

require 'graphql'
require 'apollo-federation/service'

module ApolloFederation
  module ServiceField
    extend GraphQL::Schema::Member::HasFields

    field(:_service, Service, null: false)

    def _service
      schema_class = context.schema.is_a?(GraphQL::Schema) ? context.schema.class : context.schema
      { sdl: schema_class.federation_sdl(context: context) }
    end
  end
end
