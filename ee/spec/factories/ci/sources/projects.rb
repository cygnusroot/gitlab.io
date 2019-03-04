# frozen_string_literal: true

FactoryBot.define do
  factory :ci_sources_project, class: Ci::Sources::Project do
    project factory: :project

    source_project factory: [:project, :repository]
  end
end
