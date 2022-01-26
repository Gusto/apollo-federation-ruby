# frozen_string_literal: true

module ApolloFederation
  module HasDirectives
    attr_reader :federation_directives

    def add_directive(name:, arguments: nil)
      @federation_directives ||= []
      @federation_directives << { name: name, arguments: arguments }
    end

    def to_graphql(*args, **kwargs)
      field_defn = super # Returns a GraphQL::Field
      field_defn.metadata[:federation_directives] = @federation_directives
      field_defn
    end
  end
end
