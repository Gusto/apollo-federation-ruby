# frozen_string_literal: true

module ApolloFederation
  module Tracing
    KEY = :ftv1
    DEBUG_KEY = "#{KEY}_debug".to_sym
    EXPECTED_HEADERS = [
      'apollo-federation-include-trace',
      'HTTP_APOLLO_FEDERATION_INCLUDE_TRACE',
    ].freeze

    module_function

    def use(schema)
      schema.tracer ApolloFederation::Tracing::Tracer
    end

    def should_add_traces(headers)
      headers&.values_at(*EXPECTED_HEADERS)&.any?(KEY.to_s)
    end

    # @deprecated There is no need to call this method. Traces are added to the result automatically
    def attach_trace_to_result(_result)
      warn '[DEPRECATION] `attach_trace_to_result` is deprecated. There is no need to call it, as '\
        'traces are added to the result automatically'
    end
  end
end
