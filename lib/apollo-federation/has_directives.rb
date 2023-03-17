# frozen_string_literal: true

module ApolloFederation
  module HasDirectives
    def add_directive(name:, arguments: nil)
      own_federation_directives << { name: name, arguments: arguments }
    end

    def federation_directives
      if is_a?(Class)
        own_federation_directives + find_inherited_value(:federation_directives, [])
      else
        own_federation_directives
      end
    end

    def own_federation_directives
      @own_federation_directives ||= []
    end
  end
end
