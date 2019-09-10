#!/usr/bin/env bash

set -eo pipefail

DIR=`dirname "$0"`
OUTPUT_DIR=$DIR/../lib/apollo-federation/tracing/proto

echo "Removing old client"
rm -f $OUTPUT_DIR/apollo.proto $OUTPUT_DIR/apollo_pb.rb

echo "Downloading latest Apollo Protobuf IDL"
curl --silent --output lib/apollo-federation/tracing/proto/apollo.proto https://raw.githubusercontent.com/apollographql/apollo-server/master/packages/apollo-engine-reporting-protobuf/src/reports.proto

echo "Generating Ruby client stubs"
protoc -I lib/apollo-federation/tracing/proto --ruby_out lib/apollo-federation/tracing/proto lib/apollo-federation/tracing/proto/apollo.proto
