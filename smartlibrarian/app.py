from chatbot import recommend_book
from config import validate_settings


def main() -> None:
    try:
        validate_settings()
    except Exception as exc:
        print(f"Configuration error: {exc}")
        return

    print("=" * 70)
    print("Smart Librarian — AI cu RAG + Tool Completion")
    print("Type a reading preference, then press Enter.")
    print("Type 'exit' to quit.")
    print("Example: I want a book about friendship and magic")
    print("=" * 70)

    while True:
        user_query = input("\nYou: ").strip()

        if user_query.lower() in {"exit", "quit"}:
            print("Goodbye.")
            break

        if not user_query:
            print("Please type a real question.")
            continue

        try:
            result = recommend_book(user_query)

            print("\nSmart Librarian:")
            print(result["answer"])

        except Exception as exc:
            print(f"\nError: {exc}")
            print("Tip: make sure you ran `python -m rag.index_books` first.")


if __name__ == "__main__":
    main()