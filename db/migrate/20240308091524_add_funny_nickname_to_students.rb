class AddFunnyNicknameToStudents < ActiveRecord::Migration[7.1]
  def change
    add_column :students, :funny_nickname, :string
  end
end
