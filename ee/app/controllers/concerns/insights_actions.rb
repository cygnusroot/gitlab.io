# frozen_string_literal: true

module InsightsActions
  extend ActiveSupport::Concern

  def show
    respond_to do |format|
      format.html
      format.json do
        render json: config_data
      end
    end
  end

  def query
    respond_to do |format|
      format.json do
        render json: insights_json
      end
    end
  end

  private

  def issuables
    @issuables ||= Gitlab::Insights::Finders::IssuableFinder
      .new(insights_entity, current_user, params[:query]).find
  end

  def insights_json
    case params[:name]
    when 'by_label'
      insights = reduce(issuables)
      serializer.present(insights)
    else
      raise 'Chart query not supported yet!'
    end
  end

  def reduce(issuables)
    case params[:chart_type]
    when 'stacked_bar', 'line'
      Gitlab::Insights::Reducers::LabelCountPerPeriodReducer.reduce(issuables, period: params[:query][:group_by], labels: params[:query][:collection_labels])
    when 'bar'
      Gitlab::Insights::Reducers::CountPerPeriodReducer.reduce(issuables, period: params[:query][:group_by])
    else
      raise 'Chart type not supported yet!'
    end
  end

  def serializer
    case params[:chart_type]
    when 'stacked_bar'
      Gitlab::Insights::Serializers::Chartjs::MultiSeriesSerializer
    when 'bar'
      Gitlab::Insights::Serializers::Chartjs::BarSerializer
    when 'line'
      Gitlab::Insights::Serializers::Chartjs::LineSerializer
    else
      raise 'Chart type not supported yet!'
    end
  end

  def insights_params
    params.require(:name, query: [:issuable_type]).permit(
      :issuable_state,
      :filter_labels,
      :collection_labels,
      :group_by,
      :period_limit
    )
  end

  def config_data
    [
      {
        key: 'monthlyBugsCreated',
        title: 'Monthly Bugs Created (bar)',
        type: 'bar',
        query: {
          name: 'by_label',
          params: {
            issuable_type: 'issue',
            issuable_state: 'opened',
            filter_labels: ['bug'],
            group_by: 'month',
            period_limit: 24
          }
        }
      },
      {
        key: 'weeklyBugsBySeverity',
        title: 'Weekly Bugs By Severity (stacked bar)',
        type: 'stacked_bar',
        query: {
          name: 'by_label',
          params: {
            issuable_type: 'issue',
            issuable_state: 'opened',
            filter_labels: ['bug'],
            collection_labels: ['S1','S2','S3','S4'],
            group_by: 'week',
            period_limit: 104
          }
        }
      },
      {
        key: 'monthlyBugsByTeamLine',
        title: 'Monthly Bugs By Team (line)',
        type: 'line',
        query: {
          name: 'by_label',
          params: {
            issuable_type: 'merge_request',
            issuable_state: 'opened',
            filter_labels: ['bug'],
            collection_labels: ['Manage', 'Plan', 'Create'],
            group_by: 'month',
            period_limit: 24
          }
        }
      },
      {
        key: 'issueBugsByPriority',
        title: 'Issue Bugs By Priority (pie)',
        type: 'pie',
        query: {
          name: 'by_label',
          params: {
            issuable_type: 'issue',
            issuable_state: 'opened',
            filter_labels: ['bug'],
            collection_labels: ['Manage', 'Plan', 'Create']
          }
        }
      }
    ]
  end
end
