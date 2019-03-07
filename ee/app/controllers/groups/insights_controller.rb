# frozen_string_literal: true

class Groups::InsightsController < Groups::ApplicationController
  include InsightsActions

  before_action :authorize_read_group!
  before_action :check_insights_available!

  private

  def authorize_read_group!
    render_404 unless can?(current_user, :read_group, group)
  end

  def check_insights_available!
    group.insights_available?
  end

  def insights_entity
    group
  end
end
