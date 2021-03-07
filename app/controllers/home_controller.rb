class HomeController < ApplicationController
  def index; end

  def callback
    session_code = request.env['rack.request.query_hash']['code']
    client_id = Figaro.env.github_client_id
    secret = Figaro.env.github_secret
    result = Octokit.exchange_code_for_token(session_code, client_id, secret,
                                             { accept: 'application/json' })
    session[:access_token] = result[:access_token]

    redirect_to '/repos'
  end

end
