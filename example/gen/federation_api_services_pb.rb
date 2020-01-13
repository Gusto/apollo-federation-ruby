# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: federation_api.proto for package 'graphql'

require 'grpc'
require_relative './federation_api_pb'

module Graphql
  module FederationAPI
    # The greeting service definition.
    class Service

      include GRPC::GenericService

      self.marshal_class_method = :encode
      self.unmarshal_class_method = :decode
      self.service_name = 'graphql.FederationAPI'

      # Execute the graphql query.
      rpc :execute, ExecuteRequest, ExecuteResponse
    end

    Stub = Service.rpc_stub_class
  end
end
