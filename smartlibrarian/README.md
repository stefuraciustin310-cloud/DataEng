# Smart Librarian – AI cu RAG + Tool Completion

A simple project that recommends books using:

- OpenAI GPT
- OpenAI embeddings
- ChromaDB
- RAG retrieval
- OpenAI tool/function calling
- Python CLI

## What the app does

The user enters a reading interest, for example:

- "I want a book about friendship and magic"
- "What do you recommend for someone who loves war stories?"

The app:

1. embeds the user query
2. searches a ChromaDB vector database of book summaries
3. retrieves the most relevant books
4. sends the retrieved context to an OpenAI model
5. asks the model to recommend one book
6. forces the model to call a Python tool:
   `get_summary_by_title(title: str)`
7. shows the final recommendation and the detailed summary

## Tech stack

- Python
- OpenAI Python SDK
- OpenAI Responses API
- OpenAI embeddings (`text-embedding-3-small`)
- ChromaDB
- python-dotenv
- CLI interface

## Project structure

```text
smart-librarian/
├── .venv
├── .env
├── .env.example
├── .gitignore
├── README.md
├── requirements.txt
├── app.py
├── chatbot.py
├── config.py
├── data/
│   └── book_summaries.json
├── rag/
│   ├── __init__.py
│   ├── index_books.py
│   └── retriever.py
├── tools/
│   ├── __init__.py
│   └── book_tools.py
└── storage/
    └── chroma_db/