require_relative '../gitmain'

class ReposController < ApplicationController
  def index
    @@git = GitMain.new
    @@client = @@git.init_client(session[:access_token])
    user = @@client.user
    @user_name = user[:name]
    @user_picture = user[:avatar_url]
    @@repos = @repos = @@client.repos(access_token: session[:access_token])
  end

  def show
    id = params[:id].to_i
    files = @@git.pre_process(@@client, @@repos[id - 1][:full_name])
    @results = {}
    Parallel.each(files) do |file|
      log = @@git.process_git_file(file, @@client)
      @results.store(file.to_s, log)
    end
  end
end
