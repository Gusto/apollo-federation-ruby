# frozen_string_literal: true

module ApolloFederation
  module Tracing
    KEY = :ftv1

    def self.use(schema)
      schema.tracer ApolloFederation::Tracing::Tracer
    end

    def self.should_add_traces(headers)
      headers && headers['apollo-federation-include-trace'] == KEY.to_s
    end

    def self.attach_trace_to_result(result)
      return result unless result.context[:tracing_enabled]

      trace = result.context.namespace(KEY)
      unless trace[:start_time]
        raise StandardError.new, 'Apollo Federation Tracing not installed. \
 Add `use ApollFederation::Tracing` to your schema.'
      end

      result['errors']&.each do |error|
        trace[:node_map].add_error(error)
      end

      proto = ApolloFederation::Tracing::Trace.new(
        start_time: to_proto_timestamp(trace[:start_time]),
        end_time: to_proto_timestamp(trace[:end_time]),
        duration_ns: trace[:end_time_nanos] - trace[:start_time_nanos],
        root: trace[:node_map].root,
      )

      json = result.to_h
      result[:extensions] ||= {}
      result[:extensions][KEY] = Base64.encode64(proto.class.encode(proto))

      if result.context[:debug_tracing]
        result[:extensions]["#{KEY}_debug".to_sym] = proto.to_h
      end

      json
    end

    def self.to_proto_timestamp(time)
      Google::Protobuf::Timestamp.new(seconds: time.to_i, nanos: time.nsec)
    end
  end
end
