class CreateProjectMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :project_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :role, null: false, default: "member"

      t.timestamps
    end

    add_index :project_memberships, %i[user_id project_id], unique: true
  end
end
