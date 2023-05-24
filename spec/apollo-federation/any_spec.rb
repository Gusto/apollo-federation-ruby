# frozen_string_literal: true

require 'spec_helper'
require 'apollo-federation/any'
require 'action_controller'

RSpec.describe ApolloFederation::Any do
  after do
    described_class.underscore_keys = nil
  end

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

  it 'underscore keys if Any.underscore_keys is true' do
    described_class.underscore_keys = true
    expect(
      described_class.coerce_input({ 'thingId' => 1, '__typename' => 'Thing' }, nil),
    ).to eql(thing_id: 1, __typename: 'Thing')
  end

  it 'does not underscore keys if Any.underscore_keys is false' do
    described_class.underscore_keys = false
    expect(
      described_class.coerce_input({ 'thingId' => 1, '__typename' => 'Thing' }, nil),
    ).to eql(thingId: 1, __typename: 'Thing')
  end

  it 'does not underscore keys if Any.underscore_keys is unset' do
    expect(
      described_class.coerce_input({ 'thingId' => 1, '__typename' => 'Thing' }, nil),
    ).to eql(thingId: 1, __typename: 'Thing')
  end
end
