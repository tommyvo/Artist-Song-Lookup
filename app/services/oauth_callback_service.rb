class OauthCallbackService
  # Handles OAuth callback logic, including validation and session management
  def initialize(params, session)
    @params = params
    @session = session
  end

  def call
    code = @params[:code].to_s.strip
    return error_response("Missing or invalid code parameter") if code.blank? || code.length > 200

    redirect_uri = ENV["GENIUS_REDIRECT_URI"]
    response = GeniusOauthService.exchange_code_for_token(code, redirect_uri)

    if response["access_token"]
      @session[:genius_access_token] = response["access_token"]
      if defined?(Rails) && Rails.env.development?
        { status: :ok, body: "OAuth successful! Access token: #{response["access_token"]}" }
      else
        { status: :ok, body: "OAuth successful! Access token received." }
      end
    else
      error_message = response["error"] || response["error_description"] || "Unknown error"
      { status: :unauthorized, body: "OAuth failed: #{error_message}" }
    end
  end

  private

  def error_response(message)
    { status: :bad_request, body: message }
  end
end
