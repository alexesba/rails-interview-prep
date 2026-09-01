class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :projects, :status
  end
end
