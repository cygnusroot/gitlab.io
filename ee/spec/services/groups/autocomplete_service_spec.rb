require 'spec_helper'

describe Groups::AutocompleteService do
  let!(:group) { create(:group, :nested, avatar: fixture_file_upload('spec/fixtures/dk.png')) }
  let!(:sub_group) { create(:group, parent: group) }
  let(:user) { create(:user) }
  let!(:epic) { create(:epic, group: group, author: user) }

  subject { described_class.new(group, user) }

  before do
    group.add_developer(user)
  end

  def expect_labels_to_equal(labels, expected_labels)
    extract_title = lambda { |label| label['title'] }
    expect(labels.map(&extract_title)).to eq(expected_labels.map(&extract_title))
  end

  describe '#labels_as_hash' do
    let!(:label1) { create(:group_label, group: group) }
    let!(:label2) { create(:group_label, group: group) }
    let!(:sub_group_label) { create(:group_label, group: sub_group) }
    let!(:parent_group_label) { create(:group_label, group: group.parent, group_id: group.id) }

    it 'returns labels from own group and ancestor groups' do
      results = subject.labels_as_hash(nil)

      expected_labels = [label1, label2, parent_group_label]

      expect_labels_to_equal(results, expected_labels)
    end

    context 'some labels are already assigned' do
      before do
        epic.labels << label1
      end

      it 'marks already assigned as set' do
        results = subject.labels_as_hash(epic)
        expected_labels = [label1, label2, parent_group_label]

        expect_labels_to_equal(results, expected_labels)

        assigned_label_titles = epic.labels.map(&:title)
        results.each do |hash|
          if assigned_label_titles.include?(hash['title'])
            expect(hash[:set]).to eq(true)
          else
            expect(hash.key?(:set)).to eq(false)
          end
        end
      end
    end
  end

  describe '#epics' do
    it 'returns nothing if not allowed' do
      allow(Ability).to receive(:allowed?).with(user, :read_epic, group).and_return(false)

      expect(subject.epics).to eq([])
    end

    it 'returns epics from group' do
      allow(Ability).to receive(:allowed?).with(user, :read_epic, group).and_return(true)

      expect(subject.epics).to contain_exactly(epic)
    end
  end

  describe '#commands' do
    context 'when target is an epic' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'returns available commands' do
        expect(subject.commands(epic).map { |c| c[:name] })
          .to match_array(
            [:todo, :unsubscribe, :award, :shrug, :tableflip, :cc, :title, :close]
          )
      end
    end
  end
end
