require 'spec_helper'

RSpec.describe Gitlab::Insights::Reducers::LabelCountPerPeriodReducer do
  around do |example|
    Timecop.freeze(Time.utc(2019, 3, 5)) { example.run }
  end

  let(:project) { create(:project, :public) }
  let(:label_bug) { create(:label, project: project, name: 'Bug') }
  let(:label_manage) { create(:label, project: project, name: 'Manage') }
  let(:label_plan) { create(:label, project: project, name: 'Plan') }
  let!(:issuable0) { create(:labeled_issue, :opened, created_at: Time.utc(2019, 1, 5), project: project) }
  let!(:issuable1) { create(:labeled_issue, :opened, created_at: Time.utc(2019, 1, 5), labels: [label_bug], project: project) }
  let!(:issuable2) { create(:labeled_issue, :opened, created_at: Time.utc(2019, 2, 5), labels: [label_bug, label_manage], project: project) }
  let!(:issuable3) { create(:labeled_issue, :opened, created_at: Time.utc(2019, 3, 5), labels: [label_bug, label_plan], project: project) }
  let(:opts) do
    {
      state: 'opened',
      issuable_type: 'issue',
      filter_labels: [label_bug.title],
      collection_labels: [label_manage.title, label_plan.title],
      group_by: 'month',
      period_limit: 3
    }
  end
  let(:issuable_relation) { Gitlab::Insights::Finders::IssuableFinder.new(project, nil, opts).find }

  def reduce
    described_class.reduce(issuable_relation, period: opts[:group_by], labels: opts[:collection_labels])
  end

  subject { reduce }

  let(:expected) do
    {
      'January 2019' => {
        label_manage.title => 0,
        label_plan.title => 0,
        Gitlab::Insights::UNCATEGORIZED => 1
      },
      'February 2019' => {
        label_manage.title => 1,
        label_plan.title => 0,
        Gitlab::Insights::UNCATEGORIZED => 0
      },
      'March 2019' => {
        label_manage.title => 0,
        label_plan.title => 1,
        Gitlab::Insights::UNCATEGORIZED => 0
      }
    }
  end

  it 'returns issuables with only the needed fields' do
    expect(subject).to eq(expected)
  end

  it 'avoids N + 1 queries' do
    control_count = ActiveRecord::QueryRecorder.new { subject }.count
    create(:labeled_issue, :opened, created_at: Time.utc(2019, 2, 5), labels: [label_bug], project: project)

    expect { reduce }.not_to exceed_query_limit(control_count)
  end
end
