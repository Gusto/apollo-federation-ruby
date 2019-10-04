# frozen_string_literal: true
require 'apollo-federation/has_directives'

module ApolloFederation
  module Interface
    include HasDirectives

    def extend_type
      add_directive(name: 'extends')
    end

    def key(fields:)
      add_directive(
        name: 'key',
        arguments: [
          name: 'fields',
          values: fields,
        ],
      )
    end
  end
end
