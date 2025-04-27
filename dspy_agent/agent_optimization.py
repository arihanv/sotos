import os
import pandas as pd
import dspy
from typing import Dict, List


actions = [
    "open_app(bundle_id) - Open app",
    "click_element(id) - Click on element",
    "type_in_element(id, text) - Type text into element",
    "hotkey(keys) - Execute keyboard shortcuts as a list of keys, e.g. ['cmd', 's'] or ['enter']",
    "wait(seconds) - Wait for a number of seconds (less is better)",
    "finish() - Only call in final block after executing all actions, when the entire task has been successfully completed"
]


import logging
logging.getLogger("dspy.utils.parallelizer").setLevel(logging.CRITICAL)
import logging
logging.getLogger("dspy.adapters.json_adapter").setLevel(logging.CRITICAL)
import logging
logging.getLogger("dspy.teleprompt.bootstrap").setLevel(logging.CRITICAL)


claude = dspy.LM("anthropic/claude-3-5-sonnet-20241022",max_tokens=1000, temperature=0, api_key=...)


dspy.configure(lm=claude)
#DSPy Program


class Agent(dspy.Signature):
    """You are Zeus, a macOS automation assistant designed to complete user tasks through precise UI interactions.

YOUR ROLE:
- You control macOS by clicking UI elements and using keyboard commands
- You can see and interact with all native and third-party applications
- Your goal is to complete tasks efficiently and thoroughly
- You maintain detailed state awareness throughout multi-step tasks

STATE MANAGEMENT:
- Always evaluate the success of previous actions
- Maintain a detailed memory of completed steps and progress
- Set clear next goals for each action sequence
- Track progress numerically when tasks involve multiple similar steps (e.g., "3 out of 5 emails processed")

CRITICAL RULES:
1. NEVER open an app that's already open
2. END your action sequence immediately after any operation that might trigger a popup or dialog
3. USE the wait action as little as possible
4. Use keyboard shortcuts only when you are confident the action will be successful
5. ALWAYS provide detailed state information with every response

- If no app is open (active app is "NO_APP"), first open the appropriate app:
- Only call finish() when the entire task is complete

Use only the provided list of actions. Make sure the output_action is returned as JSON with the action and its corresponding id enclosed (e.g. {"click_element": {"id": 42}})
"""
    
    past_user_actions: str = dspy.InputField(desc="the actions user has taken so far")
    open_application: str = dspy.InputField(desc="the mac os application that's open. If no app is open this is 'NO_APP'")
    current_state: str = dspy.InputField(desc="current state of the open application")
    actions: list = dspy.InputField(prefix="Actions:", desc="List of possible actions to take with brief corresponding descriptions")
    output_action: dict = dspy.OutputField(desc="next action to take from the list of possible actions in JSON with enclosed id number")


AgentProgram = dspy.ChainOfThought(Agent)


def metric(example, pred, trace=None) -> int:
    if not isinstance(example.output_action, dict) or not isinstance(pred.output_action, dict):
        return 0
    return int(example.output_action == pred.output_action)

#Sample call
# AgentProgram(past_user_actions = past_user_actions, open_application = open_application, current_state = current_state, actions = actions).output_action

class SyntheticDataGenerator(dspy.Signature):
    """Given a DSPy program signature of a task and a sample data point for that task and a desired domain, can you generate more synthetic data that is diverse and can make up a strong evaluation set? make sure that the examples are very very high quality!"""

    dspy_program: str = dspy.InputField(desc="this is the intended prompt that my downstream task model sees to complete the task of outputting an action")
    sample_data_point: dict = dspy.InputField(desc="note that there are 4 input fields and 1 output field of the ground truth output action. Note that the actions field is always the same.")
    desired_application: str = dspy.InputField(desc="relevant MacOS related application")
    desired_action: str = dspy.InputField(desc="desired action")
    output_sample_data_point: dict = dspy.OutputField(desc="next action to take only from the list of possible actions in JSON")



dspy_program = """class Agent(dspy.Signature):
    \"""You are Zeus, a macOS automation assistant designed to complete user tasks through precise UI interactions.

YOUR ROLE:
- You control macOS by clicking UI elements and using keyboard commands
- You can see and interact with all native and third-party applications
- Your goal is to complete tasks efficiently and thoroughly
- You maintain detailed state awareness throughout multi-step tasks

STATE MANAGEMENT:
- Always evaluate the success of previous actions
- Maintain a detailed memory of completed steps and progress
- Set clear next goals for each action sequence
- Track progress numerically when tasks involve multiple similar steps (e.g., "3 out of 5 emails processed")

CRITICAL RULES:
1. NEVER open an app that's already open
2. END your action sequence immediately after any operation that might trigger a popup or dialog
3. USE the wait action as little as possible
4. Use keyboard shortcuts only when you are confident the action will be successful
5. ALWAYS provide detailed state information with every response

- If no app is open (active app is "NO_APP"), first open the appropriate app:
- Only call finish() when the entire task is complete

Use only the provided list of actions. Make sure the output_action is returned as JSON with the action and its corresponding id enclosed (e.g. {"click_element": {"id": 42}})
\"""
    
    past_user_actions: str = dspy.InputField(desc="the actions user has taken so far")
    open_application: str = dspy.InputField(desc="the mac os application that's open. If no app is open this is 'NO_APP'")
    current_state: str = dspy.InputField(desc="current state of the open application")
    actions: list = dspy.InputField(prefix="Actions:", desc="List of possible actions to take with brief corresponding descriptions")
    output_action: str = dspy.OutputField(desc="next action to take from the list of possible actions in JSON with enclosed id number")
"""

# sample_data_point = {
#     "past_user_actions": past_user_actions,
#     "open_application": open_application,
#     "current_state": current_state,
#     "actions": actions,
#     "output_action": output_action
# }


synth_data = dspy.ChainOfThought(SyntheticDataGenerator)
trainset = []

for app in ['Maps', 'Safari', 'Notes', 'VSCode', 'Slack', 'Zoom', 'Google Chrome', 'Microsoft Word', 'Cursor']:
    for action in [a.split('(')[0] for a in actions]:
        result = synth_data(dspy_program = dspy_program, sample_data_point = sample_data_point, desired_application = app, desired_action = action).output_sample_data_point
        print(result)
        trainset.append(dspy.Example(
            past_user_actions=result['past_user_actions'],
            open_application = result['open_application'],
            current_state=result['current_state'],
            actions = result['actions'], 
            output_action = result['output_action']
        ).with_inputs("past_user_actions", "open_application", "current_state", "actions"))


from dspy.teleprompt import BootstrapFewShotWithRandomSearch


groq = dspy.LM(model = 'groq/llama-3.1-8b-instant', api_key = ...)
dspy.configure(lm=groq)


optimizer = BootstrapFewShotWithRandomSearch(metric=metric, num_candidate_programs=2, max_errors=5000, num_threads = 10, teacher_settings=dict(lm=claude))

#saving
compiled_program = optimizer.compile(AgentProgram, trainset = trainset)
compiled_program.save("./dspy_program_groq/", save_program=True)


#loading
groq = dspy.LM(model = 'groq/llama-3.1-8b-instant', api_key = ...)
dspy.configure(lm=groq)

loaded_dspy_program = dspy.load("./dspy_program_groq/")
# loaded_dspy_program(past_user_actions = past_user_actions, open_application = open_application, current_state = current_state, actions = actions).output_action