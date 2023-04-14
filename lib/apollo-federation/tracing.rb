# frozen_string_literal: true

module ApolloFederation
  module Tracing
    HEADER_NAME = 'HTTP_APOLLO_FEDERATION_INCLUDE_TRACE'
    KEY = :ftv1
    DEBUG_KEY = "#{KEY}_debug".to_sym

    module_function

    def use(schema)
      schema.tracer ApolloFederation::Tracing::Tracer
    end

    def should_add_traces(headers)
      headers && headers[HEADER_NAME] == KEY.to_s
    end

    # @deprecated There is no need to call this method. Traces are added to the result automatically
    def attach_trace_to_result(_result)
      warn '[DEPRECATION] `attach_trace_to_result` is deprecated. There is no need to call it, as '\
        'traces are added to the result automatically'
    end
  end
end
