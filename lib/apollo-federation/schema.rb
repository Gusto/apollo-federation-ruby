# frozen_string_literal: true

require 'apollo-federation/entities_field'
require 'apollo-federation/service_field'
require 'apollo-federation/entity'
require 'apollo-federation/federated_document_from_schema_definition.rb'

module ApolloFederation
  module Schema
    IMPORTED_DIRECTIVES = ['inaccessible', 'tag'].freeze

    def self.included(klass)
      klass.extend(CommonMethods)
    end

    module CommonMethods
      DEFAULT_LINK_NAMESPACE = 'federation'

      def federation(version: '1.0', link: {})
        @federation_version = version
        @link = { as: DEFAULT_LINK_NAMESPACE }.merge(link)
      end

      def federation_version
        @federation_version || find_inherited_value(:federation_version, '1.0')
      end

      def federation_2?
        Gem::Version.new(federation_version.to_s) >= Gem::Version.new('2.0.0')
      end

      def federation_sdl(context: nil)
        document_from_schema = FederatedDocumentFromSchemaDefinition.new(self, context: context)

        output = GraphQL::Language::Printer.new.print(document_from_schema.document)
        output.prepend(federation_2_prefix) if federation_2?
        output
      end

      def link_namespace
        @link ? @link[:as] : find_inherited_value(:link_namespace)
      end

      def query(new_query_object = nil)
        return super if new_query_object.nil? && @query_object

        @orig_query_object = new_query_object
        federation_query_object = federation_query(original_query)
        @federation_entity_type = federation_query_object.define_entities_field(schema_entities)
        @federation_query_object = federation_query_object

        super(federation_query_object)

        federation_query_object
      end

      # Types added after `query` can be entities too, so recompute `_Entity` / `Query._entities`
      # whenever the set of schema types grows. Otherwise the result depends on declaration order
      # (e.g. `orphan_types` declared after `query` silently dropped every entity).
      def orphan_types(*new_orphan_types)
        types = super
        refresh_entities_field unless new_orphan_types.empty?
        types
      end

      def mutation(new_mutation_object = nil)
        mutation_object = super
        refresh_entities_field unless new_mutation_object.nil?
        mutation_object
      end

      def subscription(new_subscription_object = nil)
        subscription_object = super
        refresh_entities_field unless new_subscription_object.nil?
        subscription_object
      end

      private

      def original_query
        @orig_query_object || find_inherited_value(:original_query)
      end

      def refresh_entities_field
        # Only the schema that declared `query` owns its federation query object. Subclasses
        # (including the temporary one built by `schema_entities`) must not redefine it.
        return unless @federation_query_object

        previous_entities = @federation_entity_type ? @federation_entity_type.possible_types : []
        entity_type = @federation_query_object.define_entities_field(schema_entities)
        return if entity_type.nil? || !respond_to?(:add_type_and_traverse, true)

        if @federation_entity_type
          register_union_members(entity_type, entity_type.possible_types - previous_entities)
        else
          register_entities_field(entity_type)
        end
      end

      # `query` traversed the Query type before `_entities` existed, so register the new `_Entity`
      # union and `_Any` scalar, and the references from `Query._entities` to them.
      def register_entities_field(entity_type)
        @federation_entity_type = entity_type
        add_type_and_traverse([entity_type, ApolloFederation::Any], root: false)

        entities_field = @federation_query_object.own_fields['_entities']
        # graphql-ruby >= 2.3 runs a field's definition block (our `representations:` argument)
        # lazily, normally while traversing its owner, which already happened in `query`.
        entities_field.ensure_loaded if entities_field.respond_to?(:ensure_loaded)
        references_to(entity_type, from: entities_field)
        references_to(ApolloFederation::Any, from: entities_field.arguments['representations'])
      end

      # The union was already registered; record membership for the entities just added to it.
      def register_union_members(entity_type, new_entities)
        new_entities.each do |entity|
          memberships = own_union_memberships[entity.graphql_name] ||= []
          memberships << entity_type unless memberships.include?(entity_type)
        end
      end

      def federation_2_prefix
        federation_namespace = ", as: \"#{link_namespace}\"" if link_namespace != DEFAULT_LINK_NAMESPACE

        <<~SCHEMA
          extend schema
            @link(url: "https://specs.apollo.dev/federation/v2.3"#{federation_namespace}, import: [#{(IMPORTED_DIRECTIVES.map { |directive| "\"@#{directive}\"" }).join(', ')}])

        SCHEMA
      end

      def schema_entities
        # Create a temporary schema that inherits from this one to extract the types
        types_schema = Class.new(self)
        # Add the original query objects to the types. We have to use orphan_types here to avoid
        # infinite recursion
        types_schema.orphan_types(original_query)

        # Walk through all of the types and determine which ones are entities (any type with a
        # "key" directive)
        types_schema.send(:non_introspection_types).values.flatten.select do |type|
          # TODO: Interfaces can have a key...
          type.include?(ApolloFederation::Object) &&
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
