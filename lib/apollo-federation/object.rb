# frozen_string_literal: true

require 'apollo-federation/field_set_serializer'
require 'apollo-federation/has_directives'

module ApolloFederation
  module Object
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      include HasDirectives

      def extend_type
        add_directive(name: 'extends')
      end

      def key(fields:)
        add_directive(
          name: 'key',
          arguments: [
            name: 'fields',
            values: ApolloFederation::FieldSetSerializer.serialize(fields),
          ],
        )
      end
    end
  end
end
