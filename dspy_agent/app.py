from fastapi import FastAPI
from pydantic import BaseModel
import dspy
from dotenv import load_dotenv
import os

load_dotenv()
app = FastAPI()

groq = dspy.LM(model='groq/llama-3.1-8b-instant', api_key=os.getenv('GROQ_API_KEY'))
dspy.configure(lm=groq)

loaded_dspy_program = dspy.load("./dspy_program_groq/")
print(loaded_dspy_program.program)

class RequestData(BaseModel):
    past_user_actions: str
    open_application: str
    current_state: str
    actions: str

@app.post("/run_program")
def run_program(data: RequestData):
    result = loaded_dspy_program(
        past_user_actions=data.past_user_actions,
        open_application=data.open_application,
        current_state=data.current_state,
        actions=data.actions
    )
    return {"output_action": result.output_action}
