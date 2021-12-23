# frozen_string_literal: true

module ApolloFederation
  module HasDirectives
    attr_reader :federation_directives

    def add_directive(name:, arguments: nil)
      @federation_directives ||= []
      @federation_directives << { name: name, arguments: arguments }
    end

    if Gem::Version.new(GraphQL::VERSION) >= Gem::Version.new('1.13.1')
      def to_graphql(silence_deprecation_warning: false)
        field_defn = super # Returns a GraphQL::Field
        field_defn.metadata[:federation_directives] = @federation_directives
        field_defn
      end
    else
      def to_graphql
        field_defn = super # Returns a GraphQL::Field
        field_defn.metadata[:federation_directives] = @federation_directives
        field_defn
      end
    end
  end
end
