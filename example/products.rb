# frozen_string_literal: true

require_relative './graphql_server'

# extend type Query {
#   topProducts(first: Int = 5): [Product]
# }

# type Product @key(fields: "upc") {
#   upc: String!
#   name: String
#   price: Int
#   weight: Int
# }

PRODUCTS = [
  {
    upc: '1',
    name: 'Table',
    price: 899,
    weight: 100,
  },
  {
    upc: '2',
    name: 'Couch',
    price: 1299,
    weight: 1000,
  },
  {
    upc: '3',
    name: 'Chair',
    price: 54,
    weight: 50,
  },
].freeze

class Product < BaseObject
  key fields: :upc

  field :upc, String, null: false
  field :name, String, null: true
  field :price, Int, null: true
  field :weight, Int, null: true

  def self.resolve_reference(reference, _context)
    PRODUCTS.find { |product| product[:upc] == reference[:upc] }
  end
end

class Query < BaseObject
  field :top_products, [Product], null: false do
    argument :first, Int, required: false, default_value: 5
  end

  def top_products(first:)
    PRODUCTS.slice(0, first)
  end
end

class ProductSchema < GraphQL::Schema
  if Gem::Version.new(GraphQL::VERSION) < Gem::Version.new('1.12.0')
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
  end

  if Gem::Version.new(GraphQL::VERSION) < Gem::Version.new('2.3.0')
    use ApolloFederation::Tracing
  else
    trace_with ApolloFederation::Tracing::Tracer
  end

  include ApolloFederation::Schema

  query(Query)
end

GraphQLServer.run(ProductSchema, Port: 5003)
