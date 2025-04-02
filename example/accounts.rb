# frozen_string_literal: true

require_relative './graphql_server'

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
  key fields: :id

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

GraphQLServer.run(AccountSchema, Port: 5001)
