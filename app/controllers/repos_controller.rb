require_relative '../gitmain'

class ReposController < ApplicationController
  def index
    git = GitMain.new
    client = git.init_client(session[:access_token])
    user = client.user
    @user_name = user[:name]
    @user_picture = user[:avatar_url]
    @repos = client.repositories(user[:login])

    # log = git.process_git_file('HelloWorld.py', client)
    # results.store('HelloWorld.py', log)

    # files.each do |file|
    #   log = git.process_git_file(file, client)
    #   results.store(file.to_s, log)
    # end

    # @result = results.to_s
  end
  def show
    
  end
end
