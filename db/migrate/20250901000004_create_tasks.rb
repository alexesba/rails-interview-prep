class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "todo"
      t.integer :priority, null: false, default: 0
      t.datetime :due_at
      t.references :project, null: false, foreign_key: true
      t.references :assignee, foreign_key: { to_table: :users }
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
