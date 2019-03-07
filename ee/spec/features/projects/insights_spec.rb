# frozen_string_literal: true

require 'spec_helper'

describe 'Project Insights' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  context 'as a permitted user' do
    before  do
      project.add_maintainer(user)
      sign_in(user)
    end

    context 'with correct license' do
      before do
        stub_licensed_features(project_insights: true)
      end

      it 'has correct title' do
        visit project_insights_path(project)

        expect(page).to have_gitlab_http_status(200)
        expect(page).to have_content('Engineering Productivity Metrics')
      end
    end

    context 'without correct license' do
      before do
        stub_licensed_features(project_insights: false)
      end

      it 'returns 404' do
        visit project_insights_path(project)

        expect(page).to have_gitlab_http_status(404)
      end
    end
  end
end
