# frozen_string_literal: true

require 'spec_helper'
require 'apollo-federation/field_set_serializer'

RSpec.describe ApolloFederation::FieldSetSerializer do
  it 'serializes symbols' do
    expect(
      described_class.serialize(:id),
    ).to eql('id')
  end

  it 'serializes snake case symbols as lower camelcase' do
    expect(
      described_class.serialize(:product_id),
    ).to eql('productId')
  end

  it 'serializes arrays of symbols' do
    expect(
      described_class.serialize(%i[qualifier id]),
    ).to eql('qualifier id')
  end

  it 'serializes nested selections' do
    expect(
      described_class.serialize([:id, organization: :id]),
    ).to eql('id organization { id }')
  end

  it 'serializes strings without modification' do
    expect(
      described_class.serialize('product_id'),
    ).to eql('product_id')
  end
end
