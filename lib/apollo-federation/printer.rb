module ApolloFederation
  class Printer < GraphQL::Language::Printer
    APOLLO_DIRECTIVES = [
      'extends',
      'key',
      'requires',
      'provides',
      'external',
    ].freeze

    def print_directive_definition(directive)
      if !apollo_directive?(directive)
        super
      end
    end

    def print_document(document)
      document.definitions.map { |d| print_node(d) }.compact.join("\n\n")
    end

    private

    def apollo_directive?(directive)
      APOLLO_DIRECTIVES.include?(directive.name)
    end
  end
end
