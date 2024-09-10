# frozen_string_literal: true

require_relative './graphql_server'

# type Review @key(fields: "id") {
#   id: ID!
#   body: String
#   author: User @provides(fields: "username")
#   product: Product
# }

# extend type User @key(fields: "id") {
#   id: ID! @external
#   username: String @external
#   reviews: [Review]
# }

# extend type Product @key(fields: "upc") {
#   upc: String! @external
#   reviews: [Review]
# }

REVIEWS = [
  {
    id: '1',
    authorID: '1',
    product: { upc: '1' },
    body: 'Love it!',
  },
  {
    id: '2',
    authorID: '1',
    product: { upc: '2' },
    body: 'Too expensive.',
  },
  {
    id: '3',
    authorID: '2',
    product: { upc: '3' },
    body: 'Could be better.',
  },
  {
    id: '4',
    authorID: '2',
    product: { upc: '1' },
    body: 'Prefer something else.',
  },
].freeze

USERNAMES = [
  { id: '1', username: '@ada' },
  { id: '2', username: '@complete' },
].freeze

class Review < BaseObject
  key fields: :id

  field :id, ID, null: false
  field :body, String, null: true
  field :author, 'User', null: true, provides: { fields: :username }
  field :product, 'Product', null: true

  def author
    { __typename: 'User', id: object[:authorID] }
  end
end

class User < BaseObject
  key fields: :id
  extend_type

  field :id, ID, null: false, external: true
  field :username, String, null: true, external: true
  field :reviews, [Review], null: true

  def reviews
    REVIEWS.select { |review| review[:authorID] == object[:id] }
  end

  def username
    found = USERNAMES.find { |username| username[:id] == object[:id] }
    found ? found[:username] : nil
  end
end

class Product < BaseObject
  key fields: :upc
  extend_type

  field :upc, String, null: false, external: true
  field :reviews, [Review], null: true

  def reviews
    REVIEWS.select { |review| review[:product][:upc] == object[:upc] }
  end
end

class ReviewSchema < GraphQL::Schema
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

  orphan_types User, Review, Product
end

GraphQLServer.run(ReviewSchema, Port: 5002)
