class FilesController < ApplicationController
  layout 'application', only: :index

  def index
    @repo_name = ReposController.repo_name
    @files = ReposController.files
  end

  def show
    @styles = ''
    @table = ''
    id = params[:id].to_i
    results = ReposController.results
    file_list = results.keys
    @hashed_users = {}
    user_list = results[file_list[id - 1]][0].keys
    results = results[file_list[id - 1]]
    @colours = colour_generate(user_list)
    i = 0
    user_list.each do |x|
      @hashed_users[x] = "a%s" % Digest::MD5.hexdigest(x)
      @styles += format(".%s {background-color:#%s;} \n", @hashed_users[x], @colours[x])
      @table += format("<tr><td><span class='%s'>%s</span></td><td>%s</td><td>%s</td></tr>",
                       @hashed_users[x], x, results[0].fetch(x, 0).to_s,
                       Math.log(results[1].fetch(x, 0), 10).round(2).to_s)
      i += 1
    end
    file_processed = ReposController.git.process_git_file(file_list[id - 1], ReposController.client)
    @code = file_processed.instance_variable_get(:@code)
    @code_text = file_processed.instance_variable_get(:@code_text)
    @user_index = file_processed.instance_variable_get(:@user_index)
  end

  private

  def colour_generate(user_list)
    colours = {}
    user_list.each do |user|
      colours[user] = Random.bytes(3).unpack1('H*')
    end
    colours
  end
end
