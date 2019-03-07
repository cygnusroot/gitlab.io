require 'spec_helper'

RSpec.describe Gitlab::Insights::Finders::IssuableFinder do
  around do |example|
    Timecop.freeze(Time.utc(2019, 3, 5)) { example.run }
  end

  shared_examples_for "insights issuable finder" do
    let(:label_bug) { create(label_type, label_entity_association_key => entity, name: 'Bug') }
    let(:label_manage) { create(label_type, label_entity_association_key => entity, name: 'Manage') }
    let(:label_plan) { create(label_type, label_entity_association_key => entity, name: 'Plan') }
    let(:label_create) { create(label_type, label_entity_association_key => entity, name: 'Create') }
    let(:label_quality) { create(label_type, label_entity_association_key => entity, name: 'Quality') }
    let(:extra_issuable_attrs) { [{}, {}, {}, {}, {}, {}] }
    let!(:issuable0) { create(:"labeled_#{issuable_type}", :opened, created_at: Time.utc(2018, 2, 1), project_association_key => project, **extra_issuable_attrs[0]) }
    let!(:issuable1) { create(:"labeled_#{issuable_type}", :opened, created_at: Time.utc(2018, 2, 1), labels: [label_bug, label_manage], project_association_key => project, **extra_issuable_attrs[1]) }
    let!(:issuable2) { create(:"labeled_#{issuable_type}", :opened, created_at: Time.utc(2019, 2, 6), labels: [label_bug, label_plan], project_association_key => project, **extra_issuable_attrs[2]) }
    let!(:issuable3) { create(:"labeled_#{issuable_type}", :opened, created_at: Time.utc(2019, 2, 20), labels: [label_bug, label_create], project_association_key => project, **extra_issuable_attrs[3]) }
    let!(:issuable4) { create(:"labeled_#{issuable_type}", :opened, created_at: Time.utc(2019, 3, 5), labels: [label_bug, label_quality], project_association_key => project, **extra_issuable_attrs[4]) }
    let(:opts) do
      {
        state: 'opened',
        issuable_type: issuable_type.to_s,
        filter_labels: [label_bug.title],
        collection_labels: [label_manage.title, label_plan.title, label_create.title],
        group_by: 'month'
      }
    end

    def find
      described_class.new(entity, nil, opts).find
    end

    subject { find }

    it 'avoids N + 1 queries' do
      control_count = ActiveRecord::QueryRecorder.new { find.map { |i| i.labels.map(&:title) } }.count
      create(:"labeled_#{issuable_type}", :opened, created_at: Time.utc(2018, 2, 1), labels: [label_bug], project_association_key => project, **extra_issuable_attrs[5])

      expect { find.map { |i| i.labels.map(&:title) } }.not_to exceed_query_limit(control_count)
    end

    context 'period_limit parameter' do
      context 'with group_by: "day"' do
        before do
          opts.merge!(group_by: 'day')
        end

        it 'returns issuable created after 30 days ago' do
          expect(subject.to_a).to eq([issuable2, issuable3, issuable4])
        end
      end

      context 'with group_by: "day", period_limit: 1' do
        before do
          opts.merge!(group_by: 'day', period_limit: 1)
        end

        it 'returns issuable created after one day ago' do
          expect(subject.to_a).to eq([issuable4])
        end
      end

      context 'with group_by: "week"' do
        before do
          opts.merge!(group_by: 'week')
        end

        it 'returns issuable created after 4 weeks ago' do
          expect(subject.to_a).to eq([issuable2, issuable3, issuable4])
        end
      end

      context 'with group_by: "week", period_limit: 1' do
        before do
          opts.merge!(group_by: 'week', period_limit: 1)
        end

        it 'returns issuable created after one week ago' do
          expect(subject.to_a).to eq([issuable4])
        end
      end

      context 'with group_by: "month"' do
        before do
          opts.merge!(group_by: 'month')
        end

        it 'returns issuable created after 12 months ago' do
          expect(subject.to_a).to eq([issuable2, issuable3, issuable4])
        end
      end

      context 'with group_by: "month", period_limit: 1' do
        before do
          opts.merge!(group_by: 'month', period_limit: 1)
        end

        it 'returns issuable created after one month ago' do
          expect(subject.to_a).to eq([issuable2, issuable3, issuable4])
        end
      end
    end
  end

  context 'for a group' do
    let(:entity) { create(:group) }
    let(:project) { create(:project, :public, group: entity) }
    let(:label_type) { :group_label }
    let(:label_entity_association_key) { :group }

    context 'issues' do
      include_examples "insights issuable finder" do
        let(:issuable_type) { :issue }
        let(:project_association_key) { :project }
      end
    end

    context 'merge requests' do
      include_examples "insights issuable finder" do
        let(:issuable_type) { :merge_request }
        let(:project_association_key) { :source_project }
        let(:extra_issuable_attrs) do
          [
            { source_branch: "add_images_and_changes" },
            { source_branch: "improve/awesome" },
            { source_branch: "feature_conflict" },
            { source_branch: "markdown" },
            { source_branch: "feature_one" },
            { source_branch: "merged-target" }
          ]
        end
      end
    end
  end

  context 'for a project' do
    let(:project) { create(:project, :public) }
    let(:entity) { project }
    let(:label_type) { :label }
    let(:label_entity_association_key) { :project }

    context 'issues' do
      include_examples "insights issuable finder" do
        let(:issuable_type) { :issue }
        let(:project_association_key) { :project }
      end
    end

    context 'merge requests' do
      include_examples "insights issuable finder" do
        let(:issuable_type) { :merge_request }
        let(:project_association_key) { :source_project }
        let(:extra_issuable_attrs) do
          [
            { source_branch: "add_images_and_changes" },
            { source_branch: "improve/awesome" },
            { source_branch: "feature_conflict" },
            { source_branch: "markdown" },
            { source_branch: "feature_one" },
            { source_branch: "merged-target" }
          ]
        end
      end
    end
  end
end
