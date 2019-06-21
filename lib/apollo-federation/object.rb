require 'apollo-federation/has_directives'

module ApolloFederation
  module Object
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      include HasDirectives

      # TODO: We should support extending interfaces at some point
      def extend_type
        add_directive(name: 'extends')
      end

      def key(fields:)
        add_directive(
          name: 'key',
          arguments: [
            name: 'fields',
            values: fields,
          ],
        )
      end
    end
  end
end
