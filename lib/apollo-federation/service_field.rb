# frozen_string_literal: true

require 'graphql'
require 'apollo-federation/service'

module ApolloFederation
  module ServiceField
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def define_service_field
        field(:_service, Service, null: false)
      end
    end

    def _service
      document_from_schema = ApolloFederation::FederatedDocumentFromSchemaDefinition.new(
        context.schema, context: context,
      )

      { sdl: GraphQL::Language::Printer.new.print(document_from_schema.document) }
    end
  end
end
