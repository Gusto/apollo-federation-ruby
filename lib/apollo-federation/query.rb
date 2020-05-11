# frozen_string_literal: true

require 'graphql'
require 'apollo-federation/service_field'
require 'apollo-federation/entities_field'

module ApolloFederation
  module Query
    def self.included(klass)
      klass.include(ServiceField)
      klass.include(EntitiesField)
    end
  end
end
