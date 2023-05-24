# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  class Any < GraphQL::Schema::Scalar
    graphql_name '_Any'

    class << self
      # Don't underscore keys by default for backwards compatibility
      attr_accessor :underscore_keys
    end

    def self.coerce_input(value, _ctx)
      # TODO: Should we convert it to a Mash-like object?
      result = {}

      # `value` can be an ActionController::Parameters instance
      value.each_pair do |key, val|
        key = GraphQL::Schema::Member::BuildType.underscore(key.to_s) if underscore_keys
        result[key.to_sym] = val
      end

      result
    end
  end
end
