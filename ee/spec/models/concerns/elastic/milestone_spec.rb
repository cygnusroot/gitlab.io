require 'spec_helper'

describe Milestone, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  context 'when global searching feature flag is off' do
    set(:project) { create :project, name: 'test1' }
    set(:milestone) { create :milestone, project: project}

    before do
      # Make sure all features are not enabled by default
      allow(Feature).to receive(:enabled?).and_return(false)
      stub_feature_flags(global_elasticsearch_search: false)
    end

    context 'when the project is not enabled specifically' do
      context '#searchable?' do
        it 'returns false' do
          expect(milestone.searchable?).to be_falsey
        end
      end
    end

    context 'when a project is enabled specifically' do
      before do
        stub_feature_flags(elasticsearch_indexing: { enabled: true, thing: project })
      end

      context '#searchable?' do
        it 'returns true' do
          expect(milestone.searchable?).to be_truthy
        end
      end
    end

    context 'when a group is enabled' do
      set(:group) { create(:group) }

      before do
        stub_feature_flags(elasticsearch_indexing: { enabled: true, thing: group })
      end

      context '#searchable?' do
        it 'returns true' do
          project = create :project, name: 'test1', group: group
          milestone = create :milestone, project: project

          expect(milestone.searchable?).to be_truthy
        end
      end
    end
  end

  it "searches milestones" do
    project = create :project

    Sidekiq::Testing.inline! do
      create :milestone, title: 'bla-bla term1', project: project
      create :milestone, description: 'bla-bla term2', project: project
      create :milestone, project: project

      # The milestone you have no access to except as an administrator
      create :milestone, title: 'bla-bla term3'

      Gitlab::Elastic::Helper.refresh_index
    end

    options = { project_ids: [project.id] }

    expect(described_class.elastic_search('(term1 | term2 | term3) +bla-bla', options: options).total_count).to eq(2)
    expect(described_class.elastic_search('bla-bla', options: { project_ids: :any }).total_count).to eq(3)
  end

  it "returns json with all needed elements" do
    milestone = create :milestone

    expected_hash = milestone.attributes.extract!(
      'id',
      'title',
      'description',
      'project_id',
      'created_at',
      'updated_at'
    ).merge({
      'join_field' => {
        'name' => milestone.es_type,
        'parent' => milestone.es_parent
      },
      'type' => milestone.es_type
    })

    expect(milestone.as_indexed_json).to eq(expected_hash)
  end

  it_behaves_like 'no results when the user cannot read cross project' do
    let(:record1) { create(:milestone, project: project, title: 'test-milestone') }
    let(:record2) { create(:milestone, project: project2, title: 'test-milestone') }
  end
end
