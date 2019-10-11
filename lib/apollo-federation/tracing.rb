# frozen_string_literal: true

module ApolloFederation
  module Tracing
    KEY = :ftv1
    DEBUG_KEY = "#{KEY}_debug".to_sym
    class NotInstalledError < StandardError
      MESSAGE = 'Apollo Federation Tracing not installed. \
Add `use ApolloFederation::Tracing` to your schema.'

      def message
        MESSAGE
      end
    end

    module_function

    def use(schema)
      schema.tracer ApolloFederation::Tracing::Tracer
    end

    def should_add_traces(headers)
      headers && headers['apollo-federation-include-trace'] == KEY.to_s
    end

    def attach_trace_to_result(result)
      return result unless result.context[:tracing_enabled]

      trace = result.context.namespace(KEY)
      raise NotInstalledError unless trace[:start_time]

      result['errors']&.each do |error|
        trace[:node_map].add_error(error)
      end

      proto = ApolloFederation::Tracing::Trace.new(
        start_time: to_proto_timestamp(trace[:start_time]),
        end_time: to_proto_timestamp(trace[:end_time]),
        duration_ns: trace[:end_time_nanos] - trace[:start_time_nanos],
        root: trace[:node_map].root,
      )

      result[:extensions] ||= {}
      result[:extensions][KEY] = Base64.encode64(proto.class.encode(proto))

      if result.context[:debug_tracing]
        result[:extensions][DEBUG_KEY] = proto.to_h
      end

      result.to_h
    end

    def to_proto_timestamp(time)
      Google::Protobuf::Timestamp.new(seconds: time.to_i, nanos: time.nsec)
    end
  end
end
