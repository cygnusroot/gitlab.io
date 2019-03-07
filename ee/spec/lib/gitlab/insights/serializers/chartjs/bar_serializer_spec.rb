require 'spec_helper'

RSpec.describe Gitlab::Insights::Serializers::Chartjs::BarSerializer do
  let(:input) { build(:insights_issuables) }

  subject { described_class.present(input) }

  it 'returns the correct format' do
    expected = {
      labels: ['Manage', 'Plan', 'Create', 'undefined'],
      datasets: [
        {
          label: nil,
          data: [1, 3, 2, 1],
          backgroundColor: ['#f58231', '#3cb44b', '#ffe119', '#808080']
        }
      ]
    }.with_indifferent_access

    expect(subject).to eq(expected)
  end
end
