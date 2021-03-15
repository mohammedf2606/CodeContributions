class FileJob
  include SuckerPunch::Job

  def perform(file, git, client)
    git.process_git_file(file, client)
  end
end
