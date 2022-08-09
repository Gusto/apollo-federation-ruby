# frozen_string_literal: true

require 'apollo-federation/entities_field'
require 'apollo-federation/service_field'
require 'apollo-federation/entity'
require 'apollo-federation/federated_document_from_schema_definition.rb'

module ApolloFederation
  module Schema
    def self.included(klass)
      klass.extend(CommonMethods)
    end

    module CommonMethods
      FEDERATION_2_PREFIX = <<~SCHEMA
        extend schema
          @link(url: "https://specs.apollo.dev/federation/v2.0")

      SCHEMA

      def federation(version: '1.0', link: {})
        @federation_version = version
        @link = { as: 'federation' }.merge(link)
      end

      def federation_version
        @federation_version || '1.0'
      end

      def federation_2?
        Gem::Version.new(federation_version.to_s) >= Gem::Version.new('2.0.0')
      end

      def federation_sdl(context: nil)
        document_from_schema = FederatedDocumentFromSchemaDefinition.new(self, context: context)

        output = GraphQL::Language::Printer.new.print(document_from_schema.document)
        output.prepend(FEDERATION_2_PREFIX) if federation_2?
        output
      end

      def link_namespace
        @link[:as]
      end

      def query(new_query_object = nil)
        if new_query_object
          @orig_query_object = new_query_object
        else
          if !@federation_query_object
            @federation_query_object = federation_query(@orig_query_object)
            @federation_query_object.define_entities_field(schema_entities)

            super(@federation_query_object)
          end

          super
        end
      end

      private

      def federation_2_prefix
        <<~SCHEMA
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.0", as: "#{link_namespace}")

        SCHEMA
      end

      def schema_entities
        # Create a temporary schema that inherits from this one to extract the types
        types_schema = Class.new(self)
        # Add the original query objects to the types. We have to use orphan_types here to avoid
        # infinite recursion
        types_schema.orphan_types(@orig_query_object)

        # Walk through all of the types and determine which ones are entities (any type with a
        # "key" directive)
        types_schema.types.values.select do |type|
          # TODO: Interfaces can have a key...
          !type.introspection? && type.include?(ApolloFederation::Object) &&
            type.federation_directives&.any? { |directive| directive[:name] == 'key' }
        end
      end

      def federation_query(query_obj)
        # Build the new query object with the '_service' field
        if query_obj.nil?
          base = GraphQL::Schema::Object
        elsif Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('1.10.0')
          base = query_obj
        else
          base = query_obj.metadata[:type_class]
        end

        klass = Class.new(base) do
          # TODO: Maybe the name should inherit from the original Query name
          # Or MAYBE we should just modify the original class?
          graphql_name 'Query'

          include EntitiesField
          include ServiceField
        end

        klass.define_service_field
        klass
      end
    end
  end
end
