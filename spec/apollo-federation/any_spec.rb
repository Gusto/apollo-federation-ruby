# frozen_string_literal: true

require 'spec_helper'
require 'apollo-federation/any'
require 'action_controller'

RSpec.describe ApolloFederation::Any do
  it 'converts the keys to symbols' do
    expect(
      described_class.coerce_input({ 'one' => 1, 'two' => 2, '__typename' => 'Thing' }, nil),
    ).to eql(one: 1, two: 2, __typename: 'Thing')
  end

  it 'converts ActionController::Parameters' do
    params = ActionController::Parameters.new(
      'one' => 1, 'two' => 2, '__typename' => 'Thing',
    )
    expect(
      described_class.coerce_input(params, nil),
    ).to eql(one: 1, two: 2, __typename: 'Thing')
  end

  it 'converts GraphQL::Language::Nodes::InputObject' do
    params = GraphQL::Language::Nodes::InputObject.new(
      arguments: [
        GraphQL::Language::Nodes::Argument.new(name: 'one', value: 1),
        GraphQL::Language::Nodes::Argument.new(name: 'two', value: 2),
        GraphQL::Language::Nodes::Argument.new(name: '__typename', value: 'Thing'),
      ],
    )
    expect(
      described_class.coerce_input(params, nil),
    ).to eql(one: 1, two: 2, __typename: 'Thing')
  end

  it 'raises an error on unsupported type' do
    expect do
      described_class.coerce_input([], nil)
    end.to raise_error(ApolloFederation::IncoercibleAnyTypeError)
  end
end
