# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_03_08_231888) do

  create_table 'commits', id: false, force: :cascade do |t|
    t.string 'commit_id'
    t.string 'author'
    t.string 'author_email'
    t.datetime 'author_time'
    t.string 'file'
    t.index ['commit_id', 'file'], name: 'index_commits_on_commit_id_and_file', unique: true
  end

end
