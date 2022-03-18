# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  module Directives
    class Key < GraphQL::Schema::Directive
      argument :fields, String, required: true
      locations OBJECT, INTERFACE
      repeatable true
    end
  end
end
