# frozen_string_literal: true

require 'graphql'

module ApolloFederation
  module Directives
    class Extends < GraphQL::Schema::Directive
      locations OBJECT, INTERFACE
    end
  end
end
