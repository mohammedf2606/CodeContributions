class WelcomeController < ApplicationController
  def setup
    repo = Rugged::Repository.new('D:/GitHub/benchmark-code-contributions')
    'HELLO' unless repo.empty?
  end
end

