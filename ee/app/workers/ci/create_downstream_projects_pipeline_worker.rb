# frozen_string_literal: true

module Ci
  class CreateDownstreamProjectsPipelineWorker
    include ::ApplicationWorker
    include ::PipelineQueue

    def perform(pipeline_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        pipeline.project.downstream_projects.each do |project|
          ::Ci::CreateDownstreamProjectPipelineService
            .new(pipeline.project, pipeline.user)
            .execute(project, pipeline.user)
        end
      end
    end
  end
end
