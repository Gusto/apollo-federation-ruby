# frozen_string_literal: true

require 'graphql'
require 'apollo-federation/service'

module ApolloFederation
  class FederatedDocumentFromSchemaDefinition < GraphQL::Language::DocumentFromSchemaDefinition
    include BackwardCompatibility

    FEDERATION_TYPES = [
      '_Any',
      '_Entity',
      '_Service',
    ].freeze
    FEDERATION_QUERY_FIELDS = [
      '_entities',
      '_service',
    ].freeze

    def build_object_type_node(object_type)
      object_node = super
      if query_type?(object_type)
        federation_fields = object_node.fields.select do |field|
          FEDERATION_QUERY_FIELDS.include?(field.name)
        end
        federation_fields.each { |field| object_node = object_node.delete_child(field) }
      end
      merge_directives(object_node, extract_federation_directives(object_type))
    end

    def build_interface_type_node(interface_type)
      merge_directives(super, extract_federation_directives(interface_type))
    end

    def build_field_node(field_type)
      merge_directives(super, extract_federation_directives(field_type))
    end

    def build_type_definition_nodes(types)
      non_federation_types = types.select do |type|
        if query_type?(type)
          !type.fields.values.all? { |field| FEDERATION_QUERY_FIELDS.include?(field.graphql_name) }
        else
          !FEDERATION_TYPES.include?(type.graphql_name)
        end
      end
      super(non_federation_types)
    end

    private

    def query_type?(type)
      type == warden.root_type_for_operation('query')
    end

    def merge_directives(node, directives)
      (directives || []).reduce(node) do |reduced_node, directive|
        reduced_node.merge_directive(
          name: directive[:name],
          arguments: build_arguments_node(directive[:arguments]),
        )
      end
    end

    def build_arguments_node(arguments)
      (arguments || []).map { |arg| build_argument(arg) }
    end

    def build_argument(arg)
      GraphQL::Language::Nodes::Argument.new(name: arg[:name], value: arg[:values])
    end

    def extract_federation_directives(type)
      get_graphql_type_metadata(type)[:federation_directives]
    end
  end
end
