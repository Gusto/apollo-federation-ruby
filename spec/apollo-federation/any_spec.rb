# frozen_string_literal: true

require 'spec_helper'
require 'apollo-federation/any'

RSpec.describe ApolloFederation::Any do
  it 'converts the keys to symbols' do
    expect(
      described_class.coerce_input({ 'one' => 1, 'two' => 2, '__typename' => 'Thing' }, nil),
    ).to eql(one: 1, two: 2, __typename: 'Thing')
  end
end
