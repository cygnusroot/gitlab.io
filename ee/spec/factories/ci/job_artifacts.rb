# frozen_string_literal: true

FactoryBot.define do
  factory :ee_ci_job_artifact, class: ::Ci::JobArtifact, parent: :ci_job_artifact do
    trait :sast do
      file_type :sast
      file_format :gzip

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security/sast.json.gz'), 'application/x-gzip')
      end
    end

    trait :sast_with_corrupted_data do
      file_type :sast
      file_format :gzip

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security/sast_with_corrupted_data.json.gz'), 'application/x-gzip')
      end
    end
  end
end
