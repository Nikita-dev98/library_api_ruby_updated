class BooksController < ApplicationController
  before_action :set_book, only: [:show, :update, :destroy, :borrow]

  # ---------- CREATE ----------
  def create
    existing = Book.find_by(
      isbn: book_params[:isbn],
      title: book_params[:title],
      author: book_params[:author],
      published_date: book_params[:published_date]
    )

    if existing
      render json: { error: "Book already exists" }, status: :bad_request
    else
      book = Book.new(book_params)
      if book.save
        render json: book, status: :ok
      else
        render json: book.errors, status: :unprocessable_entity
      end
    end
  end

  # ---------- READ ----------
  def index
    books = Book.offset(params[:skip] || 0).limit(params[:limit] || 100)
    render json: books
  end

  def show
    if @book
      render json: @book
    else
      render json: { error: "Book not found" }, status: :not_found
    end
  end

  def search
    books = Book.all
    books = books.where("title ILIKE ?", "%#{params[:title]}%") if params[:title].present?
    books = books.where("author ILIKE ?", "%#{params[:author]}%") if params[:author].present?
    render json: books
  end

  # ---------- UPDATE ----------
  def update
    if @book.update(book_params)
      render json: @book
    else
      render json: { error: "Book not found" }, status: :not_found
    end
  end

  # ---------- DELETE ----------
  def destroy
    if @book
      @book.destroy
      render json: @book
    else
      render json: { error: "Book not found" }, status: :not_found
    end
  end

  # ---------- BORROW ----------
  def borrow
    if @book.nil? || @book.status == "borrowed"
      render json: { error: "Book cannot be borrowed (maybe already borrowed)" }, status: :bad_request
    else
      @book.update(status: "borrowed", borrowed_until: Date.today + 7.days)
      render json: @book
    end
  end

  # ---------- FANCY SEARCH ----------
  def series_availability
    book_ids = params[:book_ids] || []
    check_date = Date.parse(params[:check_date]) rescue nil

    books = Book.where(id: book_ids)

    if books.size != book_ids.size
      render json: { available: false } and return
    end

    available = books.all? do |book|
      !(book.status == "borrowed" && book.borrowed_until && book.borrowed_until >= check_date)
    end

    render json: { available: available }
  end

  private

  def set_book
    @book = Book.find_by(id: params[:id])
  end

  def book_params
    params.require(:book).permit(:title, :author, :isbn, :published_date, :status, :borrowed_until, :reserved_until)
  end
end

