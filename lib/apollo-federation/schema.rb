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

        possible_entities = orig_defn.types.values.select do |type|
          !type.introspection? && !type.default_scalar? && type.is_a?(GraphQL::ObjectType) &&
            type.metadata[:federation_directives]&.any? { |directive| directive[:name] == 'key' }
        end

        @query_object = federation_query

        if !possible_entities.empty?
          entity_type = Class.new(Entity) do
            possible_types(*possible_entities)
          end
          # TODO: Should/can we encapsulate all of this inside the module? What's the best/most Ruby
          # way to split this out?
          @query_object.define_entities_field(entity_type)
        end

        super
      end

      def federation_query
        if query.nil?
          base = GraphQL::Schema::Object
        elsif Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('1.10.0')
          base = query
        else
          base = query.metadata[:type_class]
        end

        Class.new(base) do
          graphql_name 'Query'

          include EntitiesField
          include ServiceField
        end
      end

      def federation_sdl(context: nil)
        document_from_schema = FederatedDocumentFromSchemaDefinition.new(self, context: context)
        GraphQL::Language::Printer.new.print(document_from_schema.document)
      end
    end
  end
end
