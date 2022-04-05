# frozen_string_literal: true

require 'spec_helper'
require 'apollo-federation/field_set_serializer'

RSpec.describe ApolloFederation::FieldSetSerializer do
  context 'when camelize is true' do
    let(:camelize) { true }

    it 'serializes symbols' do
      expect(
        described_class.serialize(:id, camelize: camelize),
      ).to eql('id')
    end

    it 'serializes snake case symbols as lower camelcase' do
      expect(
        described_class.serialize(:product_id, camelize: camelize),
      ).to eql('productId')
    end

    it 'serializes arrays of symbols' do
      expect(
        described_class.serialize(%i[qualifier id], camelize: camelize),
      ).to eql('qualifier id')
    end

    it 'serializes nested selections' do
      expect(
        described_class.serialize([:id, organization: :id], camelize: camelize),
      ).to eql('id organization { id }')
    end

    it 'serializes strings' do
      expect(
        described_class.serialize('product_id', camelize: camelize),
      ).to eql('productId')
    end
  end

  context 'when camelize is false' do
    let(:camelize) { false }

    it 'serializes symbols' do
      expect(
        described_class.serialize(:id, camelize: camelize),
      ).to eql('id')
    end

    it 'serializes snake case symbols without modification' do
      expect(
        described_class.serialize(:product_id, camelize: camelize),
      ).to eql('product_id')
    end

    it 'serializes arrays of symbols' do
      expect(
        described_class.serialize(%i[qualifier_id id], camelize: camelize),
      ).to eql('qualifier_id id')
    end

    it 'serializes nested selections' do
      expect(
        described_class.serialize([:id, organization: :id], camelize: camelize),
      ).to eql('id organization { id }')
    end

    it 'serializes strings without modification' do
      expect(
        described_class.serialize('product_id', camelize: camelize),
      ).to eql('product_id')
    end
  end
end
