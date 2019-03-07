require 'spec_helper'

RSpec.describe Gitlab::Insights::Reducers::CountPerLabelReducer do
  let(:project) { create(:project, :public) }
  let(:label_bug) { create(:label, project: project, name: 'Bug') }
  let(:label_manage) { create(:label, project: project, name: 'Manage') }
  let(:label_plan) { create(:label, project: project, name: 'Plan') }
  let!(:issuable0) { create(:labeled_issue, :opened, project: project) }
  let!(:issuable1) { create(:labeled_issue, :opened, labels: [label_bug], project: project) }
  let!(:issuable2) { create(:labeled_issue, :opened, labels: [label_bug, label_manage], project: project) }
  let!(:issuable3) { create(:labeled_issue, :opened, labels: [label_bug, label_plan], project: project) }
  let(:opts) do
    {
      state: 'opened',
      issuable_type: 'issue',
      filter_labels: [label_bug.title],
      collection_labels: [label_manage.title, label_plan.title],
      group_by: 'month',
      period_limit: 1
    }
  end
  let(:issuable_relation) { Gitlab::Insights::Finders::IssuableFinder.new(project, nil, opts).find }

  def reduce
    described_class.reduce(issuable_relation, labels: opts[:collection_labels])
  end

  subject { reduce }

  let(:expected) do
    {
      label_manage.title => 1,
      label_plan.title => 1,
      Gitlab::Insights::UNCATEGORIZED => 1
    }
  end

  it 'returns issuables with only the needed fields' do
    expect(subject).to eq(expected)
  end

  it 'avoids N + 1 queries' do
    control_count = ActiveRecord::QueryRecorder.new { subject }.count
    create(:labeled_issue, :opened, labels: [label_bug], project: project)

    expect { reduce }.not_to exceed_query_limit(control_count)
  end
end
