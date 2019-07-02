# frozen_string_literal: true

require 'rack'
require 'json'
require 'graphql'
require 'pry-byebug'
require 'apollo-federation'
require 'optparse'
require 'webrick'

class BaseField < GraphQL::Schema::Field
  include ApolloFederation::Field
end

class BaseObject < GraphQL::Schema::Object
  include ApolloFederation::Object

  field_class BaseField
end

class GraphQLServer
  def self.run(schema, options = {})
    test_mode = false
    handler_options = options.dup
    OptionParser.new do |opts|
      opts.on('--test', 'Run in test mode') do |test|
        test_mode = test
        if test
          handler_options.merge!(
            Logger: ::WEBrick::Log.new($stderr, ::WEBrick::Log::ERROR),
            AccessLog: [],
          )
        end
      end
    end.parse!

    Rack::Handler::WEBrick.run(GraphQLServer.new(schema), handler_options) do
      if test_mode
        $stdout.puts '_READY_'
        $stdout.flush
      end
    end
  end

  def initialize(schema)
    self.schema = schema
  end

  def call(env)
    req = Rack::Request.new(env)
    req_vars = JSON.parse(req.body.read)
    query = req_vars['query']
    operation_name = req_vars['operationName']
    vars = req_vars['variables'] || {}

    graphql_debugging = {
      query: query,
      operationName: operation_name,
      vars: vars,
      schema: schema,
    }
    puts graphql_debugging.inspect

    result = schema.execute(
      query,
      operation_name: operation_name,
      variables: vars,
    )
    ['200', { 'Content-Type' => 'application/json' }, [JSON.dump(result.to_h)]]
  end

  private

  attr_accessor :schema
end
