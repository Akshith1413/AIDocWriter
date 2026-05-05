import asyncio
import os
import sys

# Ensure backend directory is in path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.workflow import DocumentOrchestrator
from app.schemas import GenerateRequest

async def main():
    req = GenerateRequest(
        input_text="Sample meeting notes to generate PRD. This needs to be long enough, over 20 characters.",
        template="prd",
        provider="groq-mixtral",
        model="mixtral-8x7b-32768",
        max_iterations=3
    )
    orch = DocumentOrchestrator(req)
    res = await orch.generate()
    print(res)

if __name__ == "__main__":
    asyncio.run(main())
