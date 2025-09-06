class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.string :title,          null: false
      t.string :author,         null: false
      t.string :isbn,           null: false
      t.date :published_date,   null:false
      t.string :status,         null: false, default:"available"
      t.date :borrowed_until
      t.date :reserved_until

      t.timestamps
    end

    # Add an index to speed up lookups, and a composite unique index to guard duplicates
    add_index :books, :isbn
    add_index :books, [:isbn, :title, :author, :published_date], unique: true, name: "index_books_on_isbn_and_book_fields"
  end
end
