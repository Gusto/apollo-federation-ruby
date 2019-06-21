require 'rack'
require 'json'
require 'graphql'
require 'pry-byebug'
require 'apollo-federation'

class BaseField < GraphQL::Schema::Field
  include ApolloFederation::Field
end

class BaseObject < GraphQL::Schema::Object
  include ApolloFederation::Object

  field_class BaseField
end

class GraphQLServer
  def self.run(schema, options = {})
    # TODO: Should this code be shared with the integration tests? If so, we should probably add
    # a command line arg to run in test mode
    Rack::Handler::WEBrick.run(
      GraphQLServer.new(schema),
      options.merge!(
        Logger: ::WEBrick::Log.new($stderr, ::WEBrick::Log::ERROR),
        AccessLog: [],
      ),
    ) do
      $stdout.puts '_READY_'
      $stdout.flush
    end
  end

  def initialize(schema)
    self.schema = schema
  end

  def call(env)
    req = Rack::Request.new(env)
    req_vars = JSON.parse(req.body.read)
    query = req_vars['query']
    operationName = req_vars["operationName"]
    vars = req_vars["variables"] || {}

    graphql_debugging = {
      query: query,
      operationName: operationName,
      vars: vars,
      schema: schema,
    }
    puts graphql_debugging.inspect

    result = schema.execute(
      query,
      operation_name: operationName,
      variables: vars
    )
    ['200', {'Content-Type' => 'application/json'}, [JSON.dump(result.to_h)]]
  end

  private

  attr_accessor :schema
end
