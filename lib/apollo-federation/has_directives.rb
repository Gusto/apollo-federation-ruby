# frozen_string_literal: true

module ApolloFederation
  module HasDirectives
    attr_reader :federation_directives

    def add_directive(name:, arguments: nil)
      @federation_directives ||= []
      @federation_directives << { name: name, arguments: arguments }
    end
  end
end
