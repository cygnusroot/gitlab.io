# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'active_model'

describe EE::Gitlab::Ci::Config::Entry::TriggeredBy do
  subject { described_class.new(config) }

  context 'when trigger config is a non-empty string' do
    let(:config) { 'some/project' }

    describe '#valid?' do
      it { is_expected.to be_valid }
    end

    describe '#value' do
      it 'is returns a trigger configuration hash' do
        expect(subject.value).to eq(project: 'some/project')
      end
    end
  end

  context 'when trigger config an empty string' do
    let(:config) { '' }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'is returns an error about an empty config' do
        expect(subject.errors.first)
          .to match /config can't be blank/
      end
    end
  end

  context 'when trigger configuration is not valid' do
    context 'when value is a number' do
      let(:config) { 123 }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns an error message' do
          expect(subject.errors.first)
            .to match /triggered by config should be a string/
        end
      end
    end
  end
end
