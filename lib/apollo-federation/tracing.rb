# frozen_string_literal: true

module ApolloFederation
  module Tracing
    HEADER_NAME = 'HTTP_APOLLO_FEDERATION_INCLUDE_TRACE'
    KEY = :ftv1
    DEBUG_KEY = "#{KEY}_debug".to_sym

    module_function

    def use(schema)
      if silence_deprecation_warning?
        schema.tracer ApolloFederation::Tracing::Tracer, silence_deprecation_warning: true
      else
        schema.tracer ApolloFederation::Tracing::Tracer
      end
    end

    def should_add_traces(headers)
      headers && headers[HEADER_NAME] == KEY.to_s
    end

    # Tracing is depreacted in graphql-ruby 2.0.0 and will be removed in 3.0.0
    # https://github.com/rmosolgo/graphql-ruby/pull/4878/files#
    def silence_deprecation_warning?
      graphql_version = Gem.loaded_specs['graphql'].version
      graphql_version >= Gem::Version.new('2') && graphql_version < Gem::Version.new('3')
    end

    # @deprecated There is no need to call this method. Traces are added to the result automatically
    def attach_trace_to_result(_result)
      warn '[DEPRECATION] `attach_trace_to_result` is deprecated. There is no need to call it, as '\
        'traces are added to the result automatically'
    end
  end
end
