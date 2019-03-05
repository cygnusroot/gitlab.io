# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
          class PopulateUpstream < Chain::Base
            def perform!
              # to be overriden in EE
            end

            def break?
              false # to be overriden in EE
            end
          end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::PopulateUpstream.prepend(EE::Gitlab::Ci::Pipeline::Chain::PopulateUpstream)
