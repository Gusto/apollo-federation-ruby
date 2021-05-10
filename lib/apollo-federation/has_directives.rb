# frozen_string_literal: true

module ApolloFederation
  module HasDirectives
    def add_directive(name:, arguments: nil)
      own_federation_directives << { name: name, arguments: arguments }
    end

    def federation_directives
      # Fields will be instances of GraphQL::Schema::Field so they can't
      # inherit directives from their ancestry chain
      return own_federation_directives if is_a?(GraphQL::Schema::Field)

      federation_directives = []
      ancestors.each do |ancestor|
        if ancestor.respond_to?(:own_federation_directives)
          federation_directives.concat(ancestor.own_federation_directives)
        end
      end
      federation_directives
    end

    def own_federation_directives
      @own_federation_directives ||= []
    end

    def to_graphql
      field_defn = super # Returns a GraphQL::Field
      field_defn.metadata[:federation_directives] = federation_directives
      field_defn
    end
  end
end
