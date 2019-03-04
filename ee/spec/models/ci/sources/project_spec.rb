# frozen_string_literal: true

require 'spec_helper'

describe Ci::Sources::Project do
  it { is_expected.to belong_to(:project) }

  it { is_expected.to belong_to(:source_project) }

  it { is_expected.to validate_presence_of(:project) }
  it { is_expected.to validate_presence_of(:source_project) }
end
