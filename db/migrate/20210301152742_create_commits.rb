class CreateCommits < ActiveRecord::Migration[6.0]
  def change
    create_table :commits do |t|
      t.string :commit_id
      t.string :author
      t.string :author_email
      t.datetime :author_time
      t.string :committer
      t.string :committer_email
      t.datetime :committer_date
      t.string :file
    end
  end
end

