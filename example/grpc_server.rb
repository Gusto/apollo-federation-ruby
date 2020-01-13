require 'graphql'
require 'grpc'
require 'json'
require_relative './gen/federation_api_pb'
require_relative './gen/federation_api_services_pb'

# grpc_tools_ruby_protoc -I proto/ --ruby_out=gen/ --grpc_out=gen/ proto/federation_api.proto

class ServerImpl < Graphql::FederationAPI::Service
  def initialize(schema)
    self.schema = schema
  end

  def execute(request, _call)
    req_vars = JSON.parse(request.body)
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

    Graphql::ExecuteResponse.new(body: JSON.dump(result.to_h))
  end

  private

  attr_accessor :schema
end

class GrpcServer
  def self.run(schema, options = {})
    port = "0.0.0.0:#{options[:Port]}"
    s = GRPC::RpcServer.new
    s.add_http2_port(port, :this_port_is_insecure)
    GRPC.logger.info("... running insecurely on #{port}")
    s.handle(ServerImpl.new(schema))
    # Runs the server with SIGHUP, SIGINT and SIGQUIT signal handlers to
    #   gracefully shutdown.
    # User could also choose to run server via call to run_till_terminated
    s.run_till_terminated_or_interrupted([1, 'int', 'SIGQUIT'])
  end
end
