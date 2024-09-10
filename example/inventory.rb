# frozen_string_literal: true

require_relative './graphql_server'

# extend type Product @key(fields: "upc") {
#   upc: String! @external
#   weight: Int @external
#   price: Int @external
#   inStock: Boolean
#   shippingEstimate: Int @requires(fields: "price weight")
# }

INVENTORY = [
  { upc: '1', in_stock: true },
  { upc: '2', in_stock: false },
  { upc: '3', in_stock: true },
].freeze

class Product < BaseObject
  extend_type
  key fields: :upc

  field :upc, String, null: false, external: true
  field :weight, Int, null: true, external: true
  field :price, Int, null: true, external: true
  field :in_stock, Boolean, null: true
  field :shipping_estimate, Int, null: true, requires: { fields: %i[price weight] }

  def self.resolve_reference(reference, _context)
    reference.merge(INVENTORY.find { |product| product[:upc] == reference[:upc] })
  end

  def shipping_estimate
    # free for expensive items
    if object[:price] > 1000
      0
    else
      # estimate is based on weight
      object[:weight] * 0.5
    end
  end
end

class InventorySchema < GraphQL::Schema
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

  orphan_types Product
end

GraphQLServer.run(InventorySchema, Port: 5004)
