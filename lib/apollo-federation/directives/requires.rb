# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  module Directives
    class Requires < GraphQL::Schema::Directive
      argument :fields, String, required: true
      locations FIELD_DEFINITION
    end
  end
end
