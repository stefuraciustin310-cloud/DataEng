from pathlib import Path
import os
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
OPENAI_CHAT_MODEL = os.getenv("OPENAI_CHAT_MODEL", "gpt-4.1-mini")
OPENAI_EMBEDDING_MODEL = os.getenv("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small")
CHROMA_COLLECTION_NAME = os.getenv("CHROMA_COLLECTION_NAME", "book_summaries")
CHROMA_PATH = str((BASE_DIR / os.getenv("CHROMA_PATH", "storage/chroma_db")).resolve())
BOOK_DATA_PATH = BASE_DIR / "data" / "book_summaries.json"
TOP_K_RESULTS = int(os.getenv("TOP_K_RESULTS", "3"))


def validate_settings() -> None:
    if not OPENAI_API_KEY:
        raise RuntimeError(
            "OPENAI_API_KEY is missing. Add it to your environment or .env file."
        )