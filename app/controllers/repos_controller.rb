require_relative '../gitmain'

class ReposController < ApplicationController

  def index
    @@git = GitMain.new
    @@client = @@git.init_client(session[:access_token])
    pp session[:access_token]
    @user = @@client.user
    @profile_url = @user[:html_url]
    @@user_name = @user_name = @user[:name]
    @user_picture = @user[:avatar_url]
    @@repos = @repos = @@client.repos(access_token: session[:access_token])
  end

  def show
    id = params[:id].to_i
    @@repo_name = @repo_name = @@repos[id - 1][:full_name]
    @files = @@git.pre_process(@@client, @@repos[id - 1][:full_name])
    @results = {}
    @files.each do |file|
      log = FileJob.new.perform(file, @@git, @@client)
      @results.store(file.to_s, log)
    end
    @graphs = generate_graphs(@results)
  end

  def generate_graphs(results)
    log_base = 10
    # These hashes store the data used to generate the graphs
    sum_results = Hash.new(0)
    log_results = Hash.new(0)
    sum_results_team = Hash.new(0)
    log_results_team = Hash.new(0)
    results.each do |file|
      next if file[1].nil?

      file[1][0].each do |user|
        sum_results[user[0]] += user[1]
        if user[0].eql?(@@user_name)
          sum_results_team[@@user_name] += user[1]
        else
          sum_results_team['Rest of team'] += user[1]
        end
      end

      file[1][1].each do |user|
        log_results[user[0]] += user[1]
        if user[0].eql?(@@user_name)
          log_results_team[@@user_name] += user[1]
        else
          log_results_team['Rest of team'] += user[1]
        end
      end
      log_results.each_key do |x|
        log_results[x] = Math.log(log_results[x] + 1, log_base).round(2)
      end
      log_results_team.each_key do |x|
        log_results_team[x] = Math.log(log_results_team[x] + 1, log_base).round(2)
      end
    end
    total_lines = sum_results.values.sum * 1.0
    sum_results.each_key do |x|
      sum_results[x] = ((sum_results[x] / total_lines) * 100).round(2)
    end
    sum_results_team.each_key do |x|
      sum_results_team[x] = ((sum_results_team[x] / total_lines) * 100).round(2)
    end
    [sum_results, log_results, sum_results_team, log_results_team]
  end

  def self.repo_name
    @@repo_name
  end
end
