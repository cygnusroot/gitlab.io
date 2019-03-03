require 'fast_spec_helper'
require_dependency 'active_model'

describe EE::Gitlab::Ci::Config::Entry::Bridge do
  subject { described_class.new(config, name: :my_trigger) }

  before do
    subject.compose!
  end

  context 'when the bridge is a downstream bridge' do
    context 'when trigger config is a non-empty string' do
      let(:config) { { trigger: 'some/project' } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a bridge job configuration' do
          expect(subject.value).to eq(name: :my_trigger,
                                      trigger: { project: 'some/project' },
                                      ignore: false,
                                      stage: 'test',
                                      only: { refs: %w[branches tags] })
        end
      end
    end

    context 'when bridge trigger is a hash' do
      let(:config) do
        { trigger: { project: 'some/project', branch: 'feature' } }
      end

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a bridge job configuration hash' do
          expect(subject.value).to eq(name: :my_trigger,
                                      trigger: { project: 'some/project',
                                                 branch: 'feature' },
                                      ignore: false,
                                      stage: 'test',
                                      only: { refs: %w[branches tags] })
        end
      end
    end

    context 'when bridge configuration contains all supported keys' do
      let(:config) do
        { trigger: { project: 'some/project', branch: 'feature' },
          when: 'always',
          extends: '.some-key',
          stage: 'deploy',
          only: { variables: %w[$SOMEVARIABLE] },
          except: { refs: %w[feature] },
          variables: { VARIABLE: '123' } }
      end

      it { is_expected.to be_valid }
    end

    context 'when trigger config is nil' do
      let(:config) { { trigger: nil } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about empty trigger config' do
          expect(subject.errors.first).to match /can't be blank/
        end
      end
    end
  end

  context 'when the bridge is an upstream bridge' do
    context 'when triggered_by config is a string' do
      let(:config) { { triggered_by: 'some/project' } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a bridge job configuration' do
          expect(subject.value).to eq(name: :my_trigger,
                                      triggered_by: { project: 'some/project' },
                                      stage: 'test')
        end
      end
    end

    context 'when triggered_by config contains unsupported keys' do
      let(:config) do
        { triggered_by: 'some/project',
          when: 'always',
          extends: '.some-key',
          stage: 'deploy',
          only: { variables: %w[$SOMEVARIABLE] },
          except: { refs: %w[feature] },
          variables: { VARIABLE: '123' } }
      end

      it { is_expected.not_to be_valid }
    end

    context 'when triggered_by config is nil' do
      let(:config) { { triggered_by: nil } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about empty trigger_by config' do
          expect(subject.errors.first).to match /can't be blank/
        end
      end
    end
  end

  context 'when the bridge has both a downstream and upstream config' do
    let(:config) { { trigger: 'first/project', triggered_by: 'second/project' } }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'is returns an error about an invalid attribute' do
        expect(subject.errors.first).to match /downstream bridge config contains unknown keys: triggered_by/
      end
    end
  end

  context 'when bridge config contains unknown keys' do
    let(:config) { { unknown: 123 } }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'is returns an error message' do
        expect(subject.errors.first)
          .to match /has to be either an upstream or downstream bridge/
      end
    end
  end

  context 'when bridge config contains build-specific attributes' do
    let(:config) { { script: 'something' } }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'returns an error message' do
        expect(subject.errors.first)
          .to match /has to be either an upstream or downstream bridge/
      end
    end
  end
end
