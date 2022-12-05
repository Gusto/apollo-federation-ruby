# frozen_string_literal: true

require 'apollo-federation/has_directives'

module ApolloFederation
  module Union
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      include HasDirectives

      def tag(name:)
        add_directive(name: 'tag', arguments: [name: 'name', values: name])
      end
    end
  end
end
