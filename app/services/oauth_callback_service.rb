class OauthCallbackService
  # Handles OAuth callback logic, including validation and session management
  def initialize(params, session)
    @params = params
    @session = session
  end

  def call
    code = @params[:code].to_s.strip
    if code.blank? || code.length > 200
      Rails.logger.warn("OAuth callback failed: missing or invalid code parameter")
      return error_response("Missing or invalid code parameter")
    end

    redirect_uri = ENV["GENIUS_REDIRECT_URI"]
    response = GeniusOauthService.exchange_code_for_token(code, redirect_uri)

    if response["access_token"]
      @session[:genius_access_token] = response["access_token"]
      session_id = @session.respond_to?(:id) ? @session.id : "unknown"
      Rails.logger.info("OAuth successful for session id: #{session_id}")
      { status: 200, body: "OAuth successful! Access token received." }
    else
      error_message = response["error"] || response["error_description"] || "Unknown error"
      Rails.logger.warn("OAuth token exchange failed: #{error_message}")
      { status: :unauthorized, body: "OAuth failed: #{error_message}" }
    end
  end

  private

  def error_response(message)
    { status: :bad_request, body: message }
  end
end
