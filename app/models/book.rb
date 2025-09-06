class Book < ApplicationRecord
  # -------------------- VALIDATIONS --------------------
  validates :title, presence: true
  validates :author, presence: true
  validates :isbn, presence: true
  validates :published_date, presence: true

  # Custom uniqueness check: ISBN can be duplicated only if title, author, and published_date also match
  validates :isbn, uniqueness: { scope: [:title, :author, :published_date],
                                message: "must be unique for given title, author, and published date" }

  # -------------------- SCOPES --------------------
  scope :search_by_title, ->(title) { where("title ILIKE ?", "%#{title}%") if title.present? }
  scope :search_by_author, ->(author) { where("author ILIKE ?", "%#{author}%") if author.present? }

  # -------------------- CRUD HELPERS --------------------
  
  def self.create_with_validation(attrs)
    existing = Book.find_by(
      isbn: attrs[:isbn],
      title: attrs[:title],
      author: attrs[:author],
      published_date: attrs[:published_date]
    )

    return nil if existing

    Book.create(attrs)
  end

  def update_book(attrs)
    update(attrs)
    self
  end

  def delete_book
    destroy
    self
  end

  # -------------------- BORROW LOGIC --------------------
  def borrow!
    return nil if status == "borrowed"

    update(
      status: "borrowed",
      borrowed_until: Date.today + 7.days
    )
    self
  end

  # -------------------- FANCY SEARCH --------------------
  def self.series_available?(book_ids, check_date)
    books = Book.where(id: book_ids)

    return false unless books.count == book_ids.length

    books.each do |book|
      if book.status == "borrowed" && book.borrowed_until && book.borrowed_until >= check_date
        return false
      end
    end

    true
  end
end

