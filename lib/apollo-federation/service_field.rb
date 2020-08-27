# frozen_string_literal: true

require 'graphql'
require 'apollo-federation/service'

module ApolloFederation
  module ServiceField
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      extend GraphQL::Schema::Member::HasFields

      def define_service_field
        field(:_service, Service, null: false)
      end
    end

    def _service
      schema_class = context.schema.is_a?(GraphQL::Schema) ? context.schema.class : context.schema
      { sdl: schema_class.federation_sdl(context: context) }
    end
  end
end
