# frozen_string_literal: true

require 'graphql'
require 'apollo-federation/service'
require 'apollo-federation/next_execution_support'

module ApolloFederation
  module ServiceField
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      extend GraphQL::Schema::Member::HasFields

      def define_service_field
        # resolve_static so Next dispatches to the class method below, not root_value.
        service_field_options = ApolloFederation::RESOLVE_STATIC_SUPPORTED ? { resolve_static: true } : {}
        field(:_service, Service, null: false, **service_field_options)
      end

      def _service(context)
        schema_class = context.schema.is_a?(GraphQL::Schema) ? context.schema.class : context.schema
        { sdl: schema_class.federation_sdl(context: context.to_h) }
      end
    end

    def _service
      self.class._service(context)
    end
  end
end
