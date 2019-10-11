# frozen_string_literal: true

require 'apollo-federation/tracing/proto'

module ApolloFederation
  module Tracing
    # NodeMap stores a flat map of trace nodes by stringified paths
    # (i.e. "_entities.0.id") for fast lookup when we need to alter
    # nodes (to add end times or errors.)
    #
    # When adding a node to the NodeMap, it will create any missing
    # parent nodes and ensure the tree is consistent.
    #
    # Only the "root" node is attached to the trace extension.
    class NodeMap
      ROOT_KEY = ''

      attr_reader :nodes
      def initialize
        @nodes = {
          ROOT_KEY => ApolloFederation::Tracing::Node.new,
        }
      end

      def root
        nodes[ROOT_KEY]
      end

      def node_for_path(path)
        nodes[array_wrap(path).join('.')]
      end

      def add(path)
        node = ApolloFederation::Tracing::Node.new
        node_key = path.join('.')
        key = path.last

        case key
        when String # field
          node.response_name = key
        when Integer # index of an array
          node.index = key
        end

        nodes[node_key] = node

        # find or create a parent node and add this node to its children
        parent_path = path[0..-2]
        parent_node = nodes[parent_path.join('.')] || add(parent_path)
        parent_node.child << node

        node
      end

      def add_error(error)
        path = array_wrap(error['path']).join('.')
        node = nodes[path] || root

        locations = array_wrap(error['locations']).map do |location|
          ApolloFederation::Tracing::Location.new(location)
        end

        node.error << ApolloFederation::Tracing::Error.new(
          message: error['message'],
          location: locations,
          json: JSON.dump(error),
        )
      end

      def array_wrap(object)
        if object.nil?
          []
        elsif object.respond_to?(:to_ary)
          object.to_ary || [object]
        else
          [object]
        end
      end
    end
  end
end
