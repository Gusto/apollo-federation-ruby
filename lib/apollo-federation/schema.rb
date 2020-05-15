# frozen_string_literal: true

require 'apollo-federation/entities_field'
require 'apollo-federation/service_field'
require 'apollo-federation/entity'
require 'apollo-federation/federated_document_from_schema_definition.rb'

module ApolloFederation
  module Schema
    def self.included(klass)
      # # TODO: Maybe make this a "use" interface?
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def query(new_query_object = nil)
        if new_query_object
          @orig_query_object = new_query_object
        else
          if !@federation_query_object
            # Build the new query object with the '_service' field
            @federation_query_object = federation_query(@orig_query_object)

            # If there are any "entities", define the Entity union and and the Query._entities field
            possible_entities = schema_entities
            if !possible_entities.empty?
              entity_type = Class.new(Entity) do
                possible_types(*possible_entities)
              end
              # TODO: Should/can we encapsulate all of this inside the module? What's the best/most
              # Ruby way to split this out?
              @federation_query_object.define_entities_field(entity_type)
            end

            super(@federation_query_object)
          end

          super
        end
      end

      def federation_sdl(context: nil)
        document_from_schema = FederatedDocumentFromSchemaDefinition.new(self, context: context)
        GraphQL::Language::Printer.new.print(document_from_schema.document)
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
            type.federation_directives&.any? { |directive| directive[:name] == 'key' }
        end
      end

      def federation_query(query_obj)
        if query_obj.nil?
          base = GraphQL::Schema::Object
        elsif Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('1.10.0')
          base = query_obj
        else
          # TODO: Will this ever happen?
          base = query_obj.metadata[:type_class]
        end

        Class.new(base) do
          # TODO: Maybe the name should inherit from the original Query name
          # Or MAYBE we should just modify the original class?
          graphql_name 'Query'

          include EntitiesField
          include ServiceField
        end
      end
    end
  end
end
