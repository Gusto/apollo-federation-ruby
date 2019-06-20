require 'graphql'

module ApolloFederation
  class Any < GraphQL::Schema::Scalar
    graphql_name '_Any'

    def self.coerce_input(value, _ctx)
      # TODO: Should we convert it to a Mash-like object?
      result = Hash.new
      value.each_key do |key|
        result[key.to_sym] = value[key]
      end

      result
    end
  end
end
