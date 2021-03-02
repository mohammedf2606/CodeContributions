require 'octokit'

class GitMain

  # Excluding files that are binary
  FILES_TO_EXCLUDE = %w[png bmp dll jpg jpeg exe ttf ico icns svg ogg].freeze

  def init_client
    @repo = 'mohammedf2606/benchmark-code-contributions'
    # Change access token depending on repositories to access
    Octokit::Client.new(access_token: 'a54f649999f6cfe204faf0f3d44a85b4d00a3746')
  end

  def store_revisions(commit_list, file_referenced)
    commit_list.each do |c|
      commit = Commit.new(commit_id: c[:sha], author: c[:author][:name],
                          author_email: c[:author][:email], author_time: c[:author][:date],
                          committer: c[:committer][:name], committer_email: c[:committer][:email],
                          committer_date: c[:committer][:date], file: file_referenced)
      commit.save
    end
  end

  def pre_process
    client = init_client
    files = []
    file = client.tree(@repo, 'HEAD', { recursive: 1 })
    file[:tree].each do |i|
      filename = i[:path]
      files.append(filename) if i[:type] != 'tree'
    end
    files
  end

  def process_git_file(filename)
    client = init_client
    filename_list = filename.split('.')
    unless FILES_TO_EXCLUDE.include?(filename_list[filename_list.length - 1])
      tracking = NilClass
      current_file = filename
      data_len = 0
      out = client.commits(@repo, path: current_file)
      commit_list = read_commits(out)
      # store_revisions(commit_list, current_file)
      i = 0
      commit_list.reverse.each do |c|
        username = c[:author][:name]
        file_contents = client.contents(@repo, { path: c[:file], ref: c[:sha] })
        data_len += file_contents.length
        if i.zero?
          tracking = Contribution.new(file_contents, username)
        else
          tracking.update(file_contents, username)
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
        author: hash.commit.author,
        committer: hash.commit.committer
      }
      results.append(c)
    end
    results
  end
end