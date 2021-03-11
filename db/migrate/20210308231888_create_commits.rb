class CreateCommits < ActiveRecord::Migration[6.0]
  def change
    create_table :commits, { id: false } do |t|
      t.string :commit_id
      t.string :author
      t.string :author_email
      t.datetime :author_time
      t.string :file
    end
    add_index :commits, %i[commit_id file], unique: true
  end
end

