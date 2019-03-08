# frozen_string_literal: true

require 'spec_helper'

describe ApprovalWrappedRule do
  using RSpec::Parameterized::TableSyntax

  let(:merge_request) { create(:merge_request) }
  let(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: approvals_required) }
  let(:approvals_required) { 0 }
  let(:approver1) { create(:user) }
  let(:approver2) { create(:user) }
  let(:approver3) { create(:user) }

  subject { described_class.new(merge_request, rule) }

  describe '#project' do
    it 'returns merge request project' do
      expect(subject.project).to eq(merge_request.target_project)
    end
  end

  describe '#approvals_left' do
    before do
      create(:approval, merge_request: merge_request, user: approver1)
      create(:approval, merge_request: merge_request, user: approver2)
      rule.users << approver1
      rule.users << approver2
    end

    context 'when approvals_required is greater than approvers number' do
      let(:approvals_required) { 8 }

      context 'when there are no unactioned approvers' do
        it 'returns 0' do
          expect(subject.approvals_left).to eq(0)
        end
      end

      context 'when there is still one unactioned approver' do
        it 'returns unactioned approver count' do
          rule.users << approver3

          expect(subject.approvals_left).to eq(1)
        end
      end
    end

    context 'when approvals_required is less than approved approver count' do
      let(:approvals_required) { 1 }

      context 'when there are no unactioned approvers' do
        it 'returns 0' do
          expect(subject.approvals_left).to eq(0)
        end
      end

      context 'when there is still one unactioned approver' do
        it 'returns unactioned approver count' do
          rule.users << approver3

          expect(subject.approvals_left).to eq(0)
        end
      end
    end
  end

  describe '#approved?' do
    before do
      create(:approval, merge_request: merge_request, user: approver1)
      rule.users << approver1
    end

    context 'when approvals left is zero' do
      let(:approvals_required) { 1 }

      it 'returns true' do
        expect(subject.approved?).to eq(true)
      end
    end

    context 'when approvals left is not zero, but there is still unactioned approvers' do
      let(:approvals_required) { 99 }

      before do
        rule.users << approver2
      end

      it 'returns false' do
        expect(subject.approved?).to eq(false)
      end
    end

    context 'when approvals left is not zero, but there is no unactioned approvers' do
      let(:approvals_required) { 99 }

      it 'returns true' do
        expect(subject.approved?).to eq(true)
      end
    end
  end

  describe '#approved_approvers' do
    context 'when some approvers has made the approvals' do
      before do
        create(:approval, merge_request: merge_request, user: approver1)
        create(:approval, merge_request: merge_request, user: approver2)

        rule.users = [approver1, approver3]
      end

      it 'returns approved approvers' do
        expect(subject.approved_approvers).to contain_exactly(approver1)
      end
    end

    context 'when merged' do
      let(:merge_request) { create(:merged_merge_request) }

      before do
        rule.approved_approvers << approver3
      end

      it 'returns approved approvers from database' do
        expect(subject.approved_approvers).to contain_exactly(approver3)
      end
    end

    context 'when merged but without materialized approved_approvers' do
      let(:merge_request) { create(:merged_merge_request) }

      before do
        create(:approval, merge_request: merge_request, user: approver1)
        create(:approval, merge_request: merge_request, user: approver2)

        rule.users = [approver1, approver3]
      end

      it 'returns computed approved approvers' do
        expect(subject.approved_approvers).to contain_exactly(approver1)
      end
    end

    context 'when project rule' do
      let(:rule) { create(:approval_project_rule, project: merge_request.project, approvals_required: approvals_required) }
      let(:merge_request) { create(:merged_merge_request) }

      before do
        create(:approval, merge_request: merge_request, user: approver1)
        create(:approval, merge_request: merge_request, user: approver2)

        rule.users = [approver1, approver3]
      end

      it 'returns computed approved approvers' do
        expect(subject.approved_approvers).to contain_exactly(approver1)
      end
    end
  end

  describe '#unactioned_approvers' do
    context 'when some approvers has not approved yet' do
      before do
        create(:approval, merge_request: merge_request, user: approver1)
        rule.users = [approver1, approver2]
      end

      it 'returns unactioned approvers' do
        expect(subject.unactioned_approvers).to contain_exactly(approver2)
      end
    end

    context 'when merged' do
      let(:merge_request) { create(:merged_merge_request) }

      before do
        rule.approved_approvers << approver3
        rule.users = [approver1, approver3]
      end

      it 'returns approved approvers from database' do
        expect(subject.unactioned_approvers).to contain_exactly(approver1)
      end
    end
  end

  describe '#approvals_required' do
    context 'for regular rules' do
      let(:rule) { create(:approval_merge_request_rule, approvals_required: 19, users: [approver1, approver2, approver3]) }

      it 'returns the model attribute capped by available approvers' do
        expect(subject.approvals_required).to eq(3)
      end
    end

    context 'for code owner rules' do
      where(:feature_enabled, :approver_count, :expected_required_approvals) do
        true  | 0 | 0
        true  | 2 | 1
        false | 2 | 0
        false | 0 | 0
      end

      with_them do
        let(:rule) do
          create(:code_owner_rule,
                 merge_request: merge_request,
                 users: create_list(:user, approver_count))
        end

        it 'returns the correct number of approvals' do
          allow(subject.project).to receive(:merge_requests_require_code_owner_approval?).and_return(feature_enabled)

          expect(subject.approvals_required).to eq(expected_required_approvals)
        end
      end
    end
  end
end
