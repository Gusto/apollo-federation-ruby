# frozen_string_literal: true

require 'apollo-federation/entities_field'
require 'apollo-federation/service_field'
require 'apollo-federation/entity'
require 'apollo-federation/federated_document_from_schema_definition.rb'

module ApolloFederation
  module Schema
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def to_graphql
        orig_defn = super

        if query.nil?
          base = GraphQL::Schema::Object
        else
          base = query.metadata[:type_class]
        end

        federation_query = Class.new(base) do
          graphql_name 'Query'

          include EntitiesField
          include ServiceField
        end

        possible_entities = orig_defn.types.values.select do |type|
          !type.introspection? && !type.default_scalar? && type.is_a?(GraphQL::ObjectType) &&
            type.metadata[:federation_directives]&.any? { |directive| directive[:name] == 'key' }
        end

        if !possible_entities.empty?
          entity_type = Class.new(Entity) do
            possible_types(*possible_entities)
          end
          # TODO: Should/can we encapsulate all of this inside the module? What's the best/most Ruby
          # way to split this out?
          federation_query.define_entities_field(entity_type)
        end

        query(federation_query)

        super
      end

      def federation_sdl
        @federation_sdl ||= begin
          document_from_schema = FederatedDocumentFromSchemaDefinition.new(self)
          GraphQL::Language::Printer.new.print(document_from_schema.document)
        end
      end
    end
  end
end
