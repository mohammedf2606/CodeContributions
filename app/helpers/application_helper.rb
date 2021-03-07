require 'octokit'

module ApplicationHelper
  def authorize
    Octokit::Client.new.authorize_url('3de3fb01fbfdf1cfa6e6', scope: 'user')
  end
end
