# frozen_string_literal: true

require 'apollo-federation/field'

module ApolloFederation
  module Resolver
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def list_size(**options)
        @list_size_options = options
      end

      def apply_list_size_directive(field)
        return unless @list_size_options

        field.add_list_size_directive(@list_size_options)
      end
    end
  end
end
