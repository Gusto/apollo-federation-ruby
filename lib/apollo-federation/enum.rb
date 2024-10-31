# frozen_string_literal: true

require 'apollo-federation/has_directives'

module ApolloFederation
  module Enum
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      include HasDirectives

      def tag(name:)
        add_directive(name: 'tag', arguments: [name: 'name', values: name])
      end

      def inaccessible
        add_directive(name: 'inaccessible')
      end

      def policy(policies)
        add_directive(
          name: 'policy',
          arguments: [
            name: 'policies',
            values: policies,
          ],
        )
      end
    end
  end
end
