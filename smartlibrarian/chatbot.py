import json

from openai import OpenAI

from config import OPENAI_CHAT_MODEL, TOP_K_RESULTS, validate_settings
from rag.retriever import search_books
from tools.book_tools import get_summary_by_title


SYSTEM_PROMPT = """
You are Smart Librarian, a friendly AI assistant that recommends books.

You will receive:
1. A user reading request
2. A short list of retrieved candidate books from a vector search

Rules:
- Use only the retrieved candidates.
- Choose exactly one strongest recommendation.
- Before writing the final answer, call get_summary_by_title with the exact title of the chosen book.
- Do not invent titles.
- The tool argument must match one of the retrieved titles exactly as written.
- After receiving the tool output, answer with exactly these sections:

Recommendation: <title> by <author>
Why it matches: <2 to 4 clear sentences>
Detailed summary: <use the tool result here>

If the tool says the title was not found, explain that briefly and use one of the retrieved exact titles.
""".strip()


TOOLS = [
    {
        "type": "function",
        "name": "get_summary_by_title",
        "description": "Return the full detailed summary for an exact book title from the local dataset. Use only a retrieved title exactly as written.",
        "strict": True,
        "parameters": {
            "type": "object",
            "properties": {
                "title": {
                    "type": "string",
                    "description": "Exact title of the selected book."
                }
            },
            "required": ["title"],
            "additionalProperties": False
        }
    }
]


def format_retrieved_candidates(candidates: list[dict]) -> str:
    blocks = []

    for index, candidate in enumerate(candidates, start=1):
        metadata = candidate.get("metadata", {})
        blocks.append(
            f"Candidate {index}\n"
            f"Exact title: {metadata.get('title', 'Unknown')}\n"
            f"Author: {metadata.get('author', 'Unknown')}\n"
            f"Themes: {metadata.get('themes', '')}\n"
            f"Short summary: {metadata.get('short_summary', '')}"
        )

    return "\n\n".join(blocks)


def execute_tool(tool_name: str, args: dict) -> str:
    if tool_name == "get_summary_by_title":
        return get_summary_by_title(args["title"])
    raise ValueError(f"Unknown tool: {tool_name}")


def recommend_book(user_query: str, top_k: int = TOP_K_RESULTS) -> dict:
    validate_settings()
    client = OpenAI()

    candidates = search_books(user_query, top_k=top_k)

    if not candidates:
        return {
            "answer": "I could not find any books in the vector database yet. Please build the index first.",
            "retrieved": []
        }

    user_input = [
        {
            "role": "user",
            "content": (
                f"User request: {user_query}\n\n"
                f"Retrieved candidates:\n{format_retrieved_candidates(candidates)}"
            )
        }
    ]

    first_response = client.responses.create(
        model=OPENAI_CHAT_MODEL,
        instructions=SYSTEM_PROMPT,
        tools=TOOLS,
        tool_choice="required",
        parallel_tool_calls=False,
        input=user_input,
    )

    # Keep building the conversation state
    user_input += first_response.output

    tool_called = False

    for item in first_response.output:
        if item.type != "function_call":
            continue

        tool_called = True
        args = json.loads(item.arguments)
        tool_output = execute_tool(item.name, args)

        user_input.append(
            {
                "type": "function_call_output",
                "call_id": item.call_id,
                "output": tool_output,
            }
        )

    if not tool_called:
        raise RuntimeError(
            "The model did not call the summary tool. Try again."
        )

    final_response = client.responses.create(
        model=OPENAI_CHAT_MODEL,
        instructions=SYSTEM_PROMPT,
        tools=TOOLS,
        tool_choice="none",
        input=user_input,
    )

    return {
        "answer": final_response.output_text,
        "retrieved": candidates,
    }