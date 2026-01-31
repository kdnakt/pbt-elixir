defmodule BookShim do
  def add_book_existing(isbn, title, author, owned, avail) do
    Bookstore.DB.add_book(isbn, title, author, owned, avail)
  end
  def add_book_new(isbn, title, author, owned, avail) do
    Bookstore.DB.add_book(isbn, title, author, owned, avail)
  end

  def add_copy_existing(isbn), do: Bookstore.DB.add_copy(isbn)
  def add_copy_new(isbn), do: Bookstore.DB.add_copy(isbn)

  def borrow_copy_avail(isbn), do: Bookstore.DB.borrow_copy(isbn)
  def borrow_copy_unavail(isbn), do: Bookstore.DB.borrow_copy(isbn)
  def borrow_copy_unknown(isbn), do: Bookstore.DB.borrow_copy(isbn)

  def return_copy_full(isbn), do: Bookstore.DB.return_copy(isbn)
  def return_copy_existing(isbn), do: Bookstore.DB.return_copy(isbn)
  def return_copy_unknown(isbn), do: Bookstore.DB.return_copy(isbn)

  def find_book_by_isbn_exists(isbn) do
    Bookstore.DB.find_book_by_isbn(isbn)
  end
  def find_book_by_isbn_unknown(isbn) do
    Bookstore.DB.find_book_by_isbn(isbn)
  end
  def find_book_by_author_matching(author) do
    Bookstore.DB.find_book_by_author(author)
  end
  def find_book_by_author_unknown(author) do
    Bookstore.DB.find_book_by_author(author)
  end

  def find_book_by_title_matching(title) do
    Bookstore.DB.find_book_by_title(title)
  end
  def find_book_by_title_unknown(title) do
    Bookstore.DB.find_book_by_title(title)
  end

end
