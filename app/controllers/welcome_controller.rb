class WelcomeController < ApplicationController
  def setup
    g = Git.open('D:/GitHub/benchmark-code-contributions')
    g.branches
  end
end
