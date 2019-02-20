# frozen_string_literal: true

class JiraConnect::ApplicationController < ApplicationController
  include Gitlab::Utils::StrongMemoize

  skip_before_action :authenticate_user!
  before_action :check_feature_flag_enabled!
  before_action :verify_atlassian_jwt!

  attr_reader :current_jira_installation

  private

  def check_feature_flag_enabled!
    return render_404 unless Feature.enabled?(:jira_connect_app)
  end

  def verify_atlassian_jwt!
    return render_403 unless atlassian_jwt_valid?

    @current_jira_installation = installation_from_jwt
  end

  def atlassian_jwt_valid?
    return false unless installation_from_jwt

    # Verify JWT signature with our stored `shared_secret`
    payload, _ = Atlassian::Jwt.decode(auth_token, installation_from_jwt.shared_secret)

    # Make sure `qsh` claim matches the current request
    payload['qsh'] == Atlassian::Jwt.create_query_string_hash(request.method, request.url, jira_connect_base_url)
  rescue JWT::DecodeError
    false
  end

  def installation_from_jwt
    return unless auth_token

    strong_memoize(:installation_from_jwt) do
      # Decode without verification to get `client_key` in `iss`
      payload, _ = Atlassian::Jwt.decode(auth_token, nil, false)
      JiraConnectInstallation.find_by_client_key(payload['iss'])
    end
  end

  def auth_token
    strong_memoize(:auth_token) do
      params[:jwt] || request.headers['Authorization']&.split(' ')&.last
    end
  end
end
