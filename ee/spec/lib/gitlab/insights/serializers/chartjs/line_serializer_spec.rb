require 'spec_helper'

RSpec.describe Gitlab::Insights::Serializers::Chartjs::LineSerializer do
  let(:input) { build(:insights_issuables_per_month) }

  subject { described_class.present(input) }

  it 'returns the correct format' do
    expected = {
      labels: ['January 2019', 'February 2019', 'March 2019'],
      datasets: [
        {
          label: 'Manage',
          data: [1, 0, 0],
          borderColor: '#f58231'
        },
        {
          label: 'Plan',
          data: [1, 1, 1],
          borderColor: '#3cb44b'
        },
        {
          label: 'Create',
          data: [1, 0, 1],
          borderColor: '#ffe119'
        },
        {
          label: 'undefined',
          data: [0, 0, 1],
          borderColor: '#808080'
        }
      ]
    }.with_indifferent_access

    expect(subject).to eq(expected)
  end
end
