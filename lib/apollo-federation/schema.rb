# frozen_string_literal: true

require 'apollo-federation/entities_field'
require 'apollo-federation/service_field'
require 'apollo-federation/entity'
require 'apollo-federation/federated_document_from_schema_definition.rb'

module ApolloFederation
  module Schema
    def self.included(klass)
      if Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('1.10.0')
        klass.extend(OneTenMethods)
      else
        klass.extend(OneNineMethods)
      end
    end

    module CommonMethods
      def federation_sdl(context: nil)
        document_from_schema = FederatedDocumentFromSchemaDefinition.new(self, context: context)
        GraphQL::Language::Printer.new.print(document_from_schema.document)
      end

      private

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

      def includes_directive?(directives, name)
        directives&.any? { |directive| directive[:name] == name }
      end
    end

    # TODO: Remove these once we drop support for graphql 1.9
    module OneNineMethods
      include CommonMethods

      def to_graphql
        orig_defn = super
        @query_object = federation_query(query)

        possible_entities = orig_defn.types.values.select do |type|
          !type.introspection? && !type.default_scalar? && type.is_a?(GraphQL::ObjectType) &&
            (includes_directive?(type.metadata[:federation_directives], 'key') ||
              type.fields.values.any? do |field|
                includes_directive?(field.metadata[:federation_directives], 'requires')
              end)
        end
        @query_object.define_entities_field(possible_entities)

        super
      end
    end

    module OneTenMethods
      include CommonMethods

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
            (includes_directive?(type.federation_directives, 'key') ||
              type.fields.values.any? do |field|
                includes_directive?(field.federation_directives, 'requires')
              end)
        end
      end
    end
  end
end
