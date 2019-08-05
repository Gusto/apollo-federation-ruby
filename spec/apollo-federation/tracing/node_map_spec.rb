# frozen_string_literal: true

require 'spec_helper'
require 'apollo-federation/tracing/node_map'

RSpec.describe ApolloFederation::Tracing::NodeMap do
  it 'creates parents for any deeply nested paths' do
    map = described_class.new
    map.add(['_entities', 0, 'reviews', 0, 'author', 'name'])
    expect(map.nodes.keys).to eq [
      '',
      '_entities.0.reviews.0.author.name',
      '_entities.0.reviews.0.author',
      '_entities.0.reviews.0',
      '_entities.0.reviews',
      '_entities.0',
      '_entities',
    ]
  end

  it 'correctly assigns the node id for index paths' do
    map = described_class.new
    map.add(['_entities', 4, 'reviews'])
    expect(map.node_for_path('_entities.4').index).to eq 4
  end

  it 'correctly assigns the node id for named paths' do
    map = described_class.new
    map.add(['_entities', 4, 'reviews'])
    expect(map.node_for_path('_entities.4.reviews').response_name).to eq 'reviews'
  end

  it 'adds errors by path' do
    map = described_class.new
    map.add(['_entities', 4, 'reviews'])

    error = {
      'path' => ['_entities', 4, 'reviews'],
      'message' => 'whoops',
      'locations' => ['line' => 2, 'column' => 4],
    }
    map.add_error(error)

    expect(map.node_for_path('_entities.4.reviews').error).to eq [
      ApolloFederation::Tracing::Error.new(
        json: JSON.dump(error),
        location: [ApolloFederation::Tracing::Location.new(line: 2, column: 4)],
        message: 'whoops',
      ),
    ]
  end

  it 'adds errors to the root object when no node is found' do
    map = described_class.new

    error = {
      'path' => ['_entities', 4, 'reviews'],
      'message' => 'whoops',
      'locations' => ['line' => 2, 'column' => 4],
    }
    map.add_error(error)

    expect(map.root.error).to eq [
      ApolloFederation::Tracing::Error.new(
        json: JSON.dump(error),
        location: [ApolloFederation::Tracing::Location.new(line: 2, column: 4)],
        message: 'whoops',
      ),
    ]
  end
end
