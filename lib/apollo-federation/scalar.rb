# frozen_string_literal: true

require 'apollo-federation/has_directives'

module ApolloFederation
  module Scalar
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
    end
  end
end
