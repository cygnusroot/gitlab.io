module EE
  module Ci
    module Pipeline
      extend ActiveSupport::Concern

      EE_FAILURE_REASONS = {
        activity_limit_exceeded: 20,
        size_limit_exceeded: 21
      }.freeze

      prepended do
        has_one :chat_data, class_name: 'Ci::PipelineChatData'

        has_many :job_artifacts, through: :builds
        has_many :vulnerabilities_occurrence_pipelines, class_name: 'Vulnerabilities::OccurrencePipeline'
        has_many :vulnerabilities, source: :occurrence, through: :vulnerabilities_occurrence_pipelines, class_name: 'Vulnerabilities::Occurrence'

        # Legacy way to fetch security reports based on job name. This has been replaced by the reports feature.
        scope :with_legacy_security_reports, -> {
          joins(:artifacts).where(ci_builds: { name: %w[sast dependency_scanning sast:container container_scanning dast] })
        }

        # This structure describes feature levels
        # to access the file types for given reports
        REPORT_LICENSED_FEATURES = {
          codequality: nil,
          sast: %i[sast],
          dependency_scanning: %i[dependency_scanning],
          container_scanning: %i[container_scanning sast_container],
          dast: %i[dast]
        }.freeze

        # Deprecated, to be removed in 12.0
        # A hash of Ci::JobArtifact file_types
        # With mapping to the legacy job names,
        # that has to contain given files
        LEGACY_REPORT_FORMATS = {
          codequality: {
            names: %w(codeclimate codequality code_quality),
            files: %w(codeclimate.json gl-code-quality-report.json)
          },
          sast: {
            names: %w(deploy sast),
            files: %w(gl-sast-report.json)
          },
          dependency_scanning: {
            names: %w(dependency_scanning),
            files: %w(gl-dependency-scanning-report.json)
          },
          container_scanning: {
            names: %w(sast:container container_scanning),
            files: %w(gl-sast-container-report.json gl-container-scanning-report.json)
          },
          dast: {
            names: %w(dast),
            files: %w(gl-dast-report.json)
          }
        }.freeze

        state_machine :status do
          after_transition any => ::Ci::Pipeline::COMPLETED_STATUSES.map(&:to_sym) do |pipeline|
            next unless pipeline.has_security_reports? && pipeline.default_branch?

            pipeline.run_after_commit do
              StoreSecurityReportsWorker.perform_async(pipeline.id)
            end
          end
        end
      end

      def any_report_artifact_for_type(file_type)
        report_artifact_for_file_type(file_type) || legacy_report_artifact_for_file_type(file_type)
      end

      def report_artifact_for_file_type(file_type)
        return unless available_licensed_report_type?(file_type)

        job_artifacts.where(file_type: ::Ci::JobArtifact.file_types[file_type]).last
      end

      def legacy_report_artifact_for_file_type(file_type)
        return unless available_licensed_report_type?(file_type)

        legacy_names = LEGACY_REPORT_FORMATS[file_type]
        return unless legacy_names

        builds.success.latest.where(name: legacy_names[:names]).each do |build|
          legacy_names[:files].each do |file_name|
            next unless build.has_artifact?(file_name)

            return OpenStruct.new(build: build, path: file_name)
          end
        end

        # In case there is no artifact return nil
        nil
      end

      def performance_artifact
        @performance_artifact ||= artifacts_with_files.find(&:has_performance_json?)
      end

      def license_management_artifact
        @license_management_artifact ||= artifacts_with_files.find(&:has_license_management_json?)
      end

      def has_license_management_data?
        license_management_artifact&.success?
      end

      def has_performance_data?
        performance_artifact&.success?
      end

      def expose_license_management_data?
        project.feature_available?(:license_management) &&
          has_license_management_data?
      end

      def expose_performance_data?
        project.feature_available?(:merge_request_performance_metrics) &&
          has_performance_data?
      end

      def has_security_reports?
        complete? && builds.latest.with_security_reports.any?
      end

      def security_reports
        ::Gitlab::Ci::Reports::Security::Reports.new.tap do |security_reports|
          builds.latest.with_security_reports.each do |build|
            build.collect_security_reports!(security_reports)
          end
        end
      end

      def license_management_report
        ::Gitlab::Ci::Reports::LicenseManagementReport.new.tap do |license_management_report|
          builds.latest.with_license_management_reports.each do |build|
            build.collect_license_management_reports!(license_management_report)
          end
        end
      end

      private

      def available_licensed_report_type?(file_type)
        feature_names = REPORT_LICENSED_FEATURES.fetch(file_type)
        feature_names.nil? || feature_names.any? { |feature| project.feature_available?(feature) }
      end

      def artifacts_with_files
        @artifacts_with_files ||= artifacts.includes(:job_artifacts_metadata, :job_artifacts_archive).to_a
      end
    end
  end
end
