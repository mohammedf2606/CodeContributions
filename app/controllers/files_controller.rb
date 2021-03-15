class FilesController < ApplicationController
  def index
    @repo_name = ReposController.repo_name
  end
  def show
  end
end
