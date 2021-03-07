require 'octokit'
require_relative 'contribution'

class GitMain

  # Excluding files that are binary
  FILES_TO_EXCLUDE = %w[png bmp dll jpg jpeg exe ttf ico icns svg ogg].freeze

  def init_client(token)
    @repo = 'mohammedf2606/benchmark-code-contributions'
    # Change access token depending on repositories to access
    Octokit::Client.new(access_token: token)
  end

  def store_revisions(commit_list, file_referenced)
    existing_commits = Commit.all.select('commit_id')
    commit_list.each do |c|
      existing_commits.each do |e|
        next if e[:commit_id].equal?(c[:sha])

        commit = Commit.new(commit_id: c[:sha], author: c[:author][:name],
                            author_email: c[:author][:email], author_time: c[:author][:date],
                            committer: c[:committer][:name], committer_email: c[:committer][:email],
                            committer_date: c[:committer][:date], file: file_referenced)
        commit.save
      end
    end
  end

  def pre_process(client)
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
      # Number of commits
      i = 0
      commit_list.reverse.each do |c|
        username = c[:author][:name]
        file_contents = client.contents(@repo, { path: current_file, ref: c[:sha] })
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