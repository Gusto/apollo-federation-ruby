# frozen_string_literal: true

require_relative './graphql_server'
require_relative './grpc_server'

# extend type Query {
#   me: User
# }

# type User @key(fields: "id") {
#   id: ID!
#   name: String
#   username: String
# }

USERS = [
  {
    id: '1',
    name: 'Ada Lovelace',
    birthDate: '1815-12-10',
    username: '@ada',
  },
  {
    id: '2',
    name: 'Alan Turing',
    birthDate: '1912-06-23',
    username: '@complete',
  },
].freeze

class User < BaseObject
  key fields: 'id'

  field :id, ID, null: false
  field :name, String, null: true
  field :username, String, null: true

  def self.resolve_reference(object, _context)
    USERS.find { |user| user[:id] == object[:id] }
  end
end

class Query < BaseObject
  field :me, User, null: true

  def me
    USERS[0]
  end
end

class AccountSchema < GraphQL::Schema
  include ApolloFederation::Schema

  query(Query)
end

# GraphQLServer.run(AccountSchema, Port: 50001)
GrpcServer.run(AccountSchema, Port: 50001)
