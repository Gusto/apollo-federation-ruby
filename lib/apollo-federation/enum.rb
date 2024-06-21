# frozen_string_literal: true

require 'apollo-federation/has_directives'

module ApolloFederation
  module Enum
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      include HasDirectives

      def authenticated
        add_directive(name: 'authenticated')
      end

      def requires_scopes(scopes)
        add_directive(name: 'tag', arguments: [name: 'scopes', values: scopes])
      end

      def tag(name:)
        add_directive(name: 'tag', arguments: [name: 'name', values: name])
      end

      def inaccessible
        add_directive(name: 'inaccessible')
      end
    end
  end
end
