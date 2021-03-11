require 'octokit'
require_relative 'contribution'

class GitMain

  # Excluding files that are binary
  FILES_TO_EXCLUDE = %w[png bmp dll jpg jpeg exe ttf ico icns svg ogg mp3].freeze

  def init_client(token)
    # Change access token depending on repositories to access
    Octokit::Client.new(access_token: token)
  end

  def store_revisions(commit_list, file_referenced)
    ActiveRecord::Base.logger.level = 1
    commit_list.each do |c|
      commit = Commit.new(commit_id: c[:sha], author: c[:author][:name],
                          author_email: c[:author][:email], author_time: c[:author][:date],
                          file: file_referenced)
      begin
        commit.save
      rescue ActiveRecord::RecordNotUnique
        next
      end
    end
  end

  def pre_process(client, repo)
    @repo = repo
    files = []
    file = client.tree(@repo, 'HEAD', { recursive: 1 })
    file[:tree].each do |i|
      filename = i[:path]
      files.append(filename) if i[:type] != 'tree'
    end
    files
  end

  def process_git_file(filename, client)
    filename_list = filename.split('.')
    unless FILES_TO_EXCLUDE.include?(filename_list[filename_list.length - 1])
      tracking = NilClass
      current_file = filename
      out = client.commits(@repo, path: current_file)
      commit_list = read_commits(out)
      store_revisions(commit_list, current_file)
      i = 0
      # Number of commits
      commit_list.reverse.each do |c|
        username = c[:author][:name]
        begin
          file_contents = client.contents(@repo, { path: current_file, ref: c[:sha] })
        rescue Octokit::NotFound
          next
        end
        file = Base64.decode64(file_contents[:content].split.join)
        if i.zero?
          tracking = Contribution.new(file, username)
        else
          tracking.update(file, username)
        end
        i += 1
      end
      tracking.calculate_ownership
    end
  end

  def read_commits(data)
    results = []
    data.each do |commit|
      hash = commit.rels[:self].get.data
      c = {
        sha: hash.sha,
        author: hash.commit.author
      }
      results.append(c)
    end
    results
  end
end
