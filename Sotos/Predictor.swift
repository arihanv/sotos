// Predictor.swift
import Foundation
import AppKit
// TODO: Import necessary modules for DOMElement, AXUIElement related constants and functions (e.g., Accessibility)
// TODO: Define or import DOMElement struct/class
// TODO: Define or import getFrontApp(), openApplication(), clickElement()

// --- Groq API Configuration ---
let groqApiKey = "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" // Replace with your actual key if needed
let groqApiUrl = "https://api.groq.com/openai/v1/chat/completions"
let groqModel = "llama-3.1-8b-instant" // Or another suitable model

let systemPrompt = """
You are Zeus, an advanced macOS automation assistant with predictive intelligence. Your core function is to analyze the current UI state and accurately predict the user's most likely next action.

## CAPABILITIES & RESPONSIBILITIES:
- You have deep understanding of macOS UI patterns and user behavior
- You can identify the most relevant clickable elements based on context
- You excel at predicting natural interaction flows in applications
- You prioritize high-confidence predictions that save users time

## CONTEXT AWARENESS:
- Consider the application currently in focus
- Analyze the hierarchy and relationships between UI elements
- Recognize common UI patterns (forms, dialogs, navigation)
- Identify primary action buttons vs secondary options

## INPUT FORMAT: 
You receive a structured DOM representation of the current screen:
[ID_NUMBER]<ELEM_TYPE>content inside</ELEM_TYPE>

Example: 
[14]<AXButton>Save</AXButton>
[27]<AXTextField>Username</AXTextField>
[38]<AXCheckBox>Remember me</AXCheckBox>

## PREDICTION STRATEGY:
1. Identify the most likely user intent based on visible elements
2. Prioritize primary actions (Save, Continue, Submit) when forms are complete
3. Suggest logical next steps in multi-step workflows
4. Consider recency and frequency of similar patterns

## OUTPUT REQUIREMENTS:
- Return EXACTLY ONE prediction in valid JSON format
- Use only actions from the provided action list
- Include the element ID for actions that require it
- Format must be: {"action_name": {"parameter": value}}
- Example: {"click_element": {"id": 42}}
- Use "none()" only when genuinely uncertain

Your prediction should be the single most likely next user action with high confidence.
"""

let availableActions = [ // Define the actions the model can choose from
    "click_element(id) - Click on element",
    "type_in_element(id, text) - Type text into element",
//    "open_app(bundle_id) - Open app",
//    "hotkey(keys) - Execute keyboard shortcuts as a list of keys, e.g. ['cmd', 's'] or ['enter']",
//    "wait(seconds) - Wait for a number of seconds (less is better)",
//    "finish() - Only call in final block after executing all actions, when the entire task has been successfully completed"
    "none() - Do nothing if uncertain" // Added none action
]
// --- End Groq API Configuration ---


var maxPastUserActions = 10
var pastUserActions = [String]()
var thedom: [Int: DOMElement] = [:] // Global DOM, consider managing state differently if needed

// Removed predictDomElement function as predictDomElementWithAction provides the necessary info


// Helper to append and trim pastUserActions
private func appendPastUserAction(_ action: String) {
    pastUserActions.append(action)
    if pastUserActions.count > maxPastUserActions {
        pastUserActions = Array(pastUserActions.suffix(maxPastUserActions))
    }
}

func execute_actions(past_actions: [String], actions_to_execute: [String]) -> (Bool, [String]) {
    var task_completed = false
    
    print("Executing actions: \(actions_to_execute)")

    for action in actions_to_execute {
        if action.contains("open_app") {
            // Parse bundle_id from action string
            if let bundleId = extractValue(from: action, key: "bundle_id") {
                do {
                    try openApplication(bundleId: bundleId) // Assumes openApplication exists
                    appendPastUserAction("✅ Opened app: \(bundleId)")
                } catch {
                    appendPastUserAction("❌ [FAILED] Opened app: \(bundleId)")
                }
            }
        } else if action.contains("click_element") {
            if let elementIdStr = extractValue(from: action, key: "id"), let elementId = Int(elementIdStr) {
                do {
                    print("!clicking element \(elementId)")
                    try clickElement(dom: thedom, clickableId: elementId) // Assumes clickElement exists
                    appendPastUserAction("✅ Clicked element: \(elementId)")
                } catch {
                    appendPastUserAction("❌ [FAILED] Clicked element: \(elementId)")
                }
            }
        } else if action.contains("type_in_element") {
            if let elementIdStr = extractValue(from: action, key: "id"),
               let text = extractValue(from: action, key: "text"),
               let elementId = Int(elementIdStr) {
                do {
                    print("!typing text \(elementId) \(text)")
                    // Find the element with the matching clickableId
                    guard let element = thedom.values.first(where: { $0.clickableId == elementId }) else {
                        throw NSError(domain: "Executor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Element not found for typing: \(elementId)"])
                    }
                    
                    // Focus the element first
                    AXUIElementSetAttributeValue(element.uielem, kAXFocusedAttribute as CFString, kCFBooleanTrue)
                    
                    // Set the text value directly using AXUIElement
                    let result = AXUIElementSetAttributeValue(element.uielem, kAXValueAttribute as CFString, text as CFTypeRef)
                    if result != .success { // Qualified with AXError
                        // Fallback to alternative attribute if the standard one fails
                        let altResult = AXUIElementSetAttributeValue(element.uielem, kAXSelectedTextAttribute as CFString, text as CFTypeRef)
                        if altResult != .success { // Qualified with AXError
                            throw NSError(domain: "Executor", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to set text value for element: \(elementId)"])
                        }
                    }

                    appendPastUserAction("✅ Typed text: \(text) into element: \(elementId)")
                } catch {
                    appendPastUserAction("❌ [FAILED] Typing text: \(text) into element: \(elementId) - \(error.localizedDescription)")
                }
            }
        } else if action.contains("hotkey") {
            if let keys = extractValue(from: action, key: "keys") {
                // TODO: Implement actual hotkey execution logic
                print("Hotkey action requested (not implemented): \(keys)")
                appendPastUserAction("⚠️ Hotkey (not implemented): \(keys)")
            }
        } else if action.contains("wait") {
            if let secondsStr = extractValue(from: action, key: "seconds"), let seconds = Double(secondsStr) {
                Thread.sleep(forTimeInterval: seconds)
                appendPastUserAction("✅ Waited \(seconds) sec")
            }
        } else if action.contains("finish") {
            task_completed = true
            appendPastUserAction("Task completed")
        } else if action.contains("none") { // Handle none action
             appendPastUserAction("🤷 No action taken (model uncertain)")
        }
    }
    
    return (task_completed, pastUserActions)
}

// Helper function to extract values from action strings like "action(key=value, key2='value2')"
// Handles simple cases, might need refinement for complex nested structures or escaped chars.
private func extractValue(from action: String, key: String) -> String? {
    // Try key="value" or key='value'
    let quotedPattern = "\(key)\\s*=\\s*[\"']([^\"']*)[\"']"
    if let range = action.range(of: quotedPattern, options: .regularExpression) {
        let result = action[range]
        // Extract the value part between the quotes
        if let firstQuoteIndex = result.firstIndex(of: "\"") ?? result.firstIndex(of: "'"),
           let lastQuoteIndex = result.lastIndex(of: "\"") ?? result.lastIndex(of: "'") {
           let startIndex = result.index(after: firstQuoteIndex)
           if startIndex < lastQuoteIndex {
               return String(result[startIndex..<lastQuoteIndex])
           }
        }
    }

    // Try key=value (no quotes, stops at comma, space, or parenthesis)
    let unquotedPattern = "\(key)\\s*=\\s*([^,\\s\\)]+)"
     if let range = action.range(of: unquotedPattern, options: .regularExpression) {
         let result = String(action[range])
         // Extract the value part after '='
         if let eqIndex = result.firstIndex(of: "=") {
             let startIndex = result.index(after: eqIndex)
             // Trim leading/trailing whitespace from the potential value
             let value = String(result[startIndex...]).trimmingCharacters(in: .whitespaces)
             // Ensure we didn't just match the key itself if it was the last thing
             if !value.isEmpty {
                 return value
             }
         }
     }

    // Try key: value (common in JSON-like strings from LLMs)
    // Handles strings like '{"id": 42, "text": "hello"}'
     let jsonKeyPattern = "[\"']?\(key)[\"']?\\s*:\\s*([\"']?)([^\"',\\}\\]]+)\\1"
     if let range = action.range(of: jsonKeyPattern, options: [.regularExpression, .caseInsensitive]) {
         // This is complex, let's try a simpler regex to just get the value part directly
         // This looks for the key (possibly quoted) followed by : and then captures the value (quoted or unquoted)
         let simplerPattern = "[\"']?\(key)[\"']?\\s*:\\s*(?:\"([^\"]*)\"|'([^']*)'|([^,\\s\\}\\]]+))"
         if let match = try? NSRegularExpression(pattern: simplerPattern).firstMatch(in: action, range: NSRange(action.startIndex..., in: action)) {
             // Check capture groups: 1 for double-quoted, 2 for single-quoted, 3 for unquoted
             if let r = Range(match.range(at: 1), in: action) { return String(action[r]) }
             if let r = Range(match.range(at: 2), in: action) { return String(action[r]) }
             if let r = Range(match.range(at: 3), in: action) { return String(action[r]) }
         }
     }


    // Try parentheses format: key(value) - Less likely with JSON output but maybe useful
    let parenthesesPattern = "\(key)\\s*\\(\\s*([^,\\)]+)\\s*\\)"
    if let range = action.range(of: parenthesesPattern, options: .regularExpression) {
        let result = action[range]
        if let openParenIndex = result.firstIndex(of: "("), let closeParenIndex = result.lastIndex(of: ")") {
            let startIndex = result.index(after: openParenIndex)
            if startIndex < closeParenIndex {
                return String(result[startIndex..<closeParenIndex])
            }
        }
    }

    print("⚠️ Could not extract key '\(key)' from action string: \(action)")
    return nil
}


// Returns (predicted DOMElement, predicted action string) by calling Groq API
func predictDomElementWithAction(dom: [Int: DOMElement], dom_str: String) -> (DOMElement?, String?) {
    thedom = dom // Update global DOM reference

    guard let url = URL(string: groqApiUrl) else {
        print("Error: Invalid Groq API URL")
        return (nil, nil)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(groqApiKey)", forHTTPHeaderField: "Authorization")

    let pastActionsString = pastUserActions.joined(separator: "\n")
    let frontAppInfo = getFrontApp() // Assumes getFrontApp returns a dictionary or similar
    // Attempt to serialize frontAppInfo, default to a simple string if fails
    let frontAppString: String
    if let jsonData = try? JSONSerialization.data(withJSONObject: frontAppInfo, options: []),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        frontAppString = jsonString
    } else {
        frontAppString = "\(frontAppInfo)" // Fallback representation
    }
    
    let actionsString = availableActions.joined(separator: "\n")


    // Construct the user prompt message
    let userMessageContent = """
    Past User Actions:
    \(pastActionsString.isEmpty ? "None" : pastActionsString)

    Open Application:
    \(frontAppString)

    Current State (DOM):
    ```
    \(dom_str)
    ```

    Available Actions:
    \(actionsString)

    Based on the current state and past actions, what is the single next action to take? Respond ONLY with the JSON for the action, ensuring the 'id' exists in the provided Current State (DOM). If you are uncertain about the next step, use the `none()` action.
    """

    let requestBody: [String: Any] = [
        "model": groqModel,
        "messages": [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userMessageContent]
        ],
        "max_tokens": 150, // Adjust as needed, should be enough for one action JSON
        "temperature": 0 // For deterministic output
    ]

    guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
        print("Error: Could not serialize request body")
        return (nil, nil)
    }
    request.httpBody = httpBody

    var predictedElement: DOMElement? = nil
    var predictedActionString: String? = nil
    let semaphore = DispatchSemaphore(value: 0)

    // --- Groq API Call ---
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }

        if let error = error {
            print("Error calling Groq API: \(error.localizedDescription)")
            return
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Error: No HTTP response received")
            return
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print("Error: Groq API returned status code \(httpResponse.statusCode)")
            if let data = data, let errorBody = String(data: data, encoding: .utf8) {
                print("Error body: \(errorBody)")
            }
            return
        }
        guard let data = data else {
            print("Error: No data received from Groq API")
            return
        }

        // Parse the Groq JSON response
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = jsonResponse["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                print("Groq Response Content: \(content)")
                predictedActionString = content.trimmingCharacters(in: .whitespacesAndNewlines)

                // Now, parse the action *within* the content string
                // Assuming content *is* the JSON string like {"click_element": {"id": 42}}
                // We need to determine the action type and find the element ID if applicable
                
                // Use extractValue to get potential action keys and IDs
                var elementId: Int? = nil
                var actionType: String?
                
                if predictedActionString?.contains("click_element") == true {
                    actionType = "click_element"
                    if let idStr = extractValue(from: predictedActionString!, key: "id"), let id = Int(idStr) {
                        elementId = id
                    }
                } else if predictedActionString?.contains("type_in_element") == true {
                    actionType = "type_in_element"
                     if let idStr = extractValue(from: predictedActionString!, key: "id"), let id = Int(idStr) {
                        elementId = id
                    }
                } else {
                     // Handle other actions like open_app, hotkey, wait, finish if needed
                     // For now, only element-related actions set predictedElement
                     actionType = predictedActionString // Or parse more specifically
                }

                // Find the DOM element if an ID was extracted
                if let id = elementId {
                    // --- Add logging for thedom keys ---
                    print("Looking for ID \(id) in thedom keys: \(thedom.keys.sorted())")
                    // --- End logging ---
                    predictedElement = dom.values.first { $0.clickableId == id }
                    if predictedElement == nil {
                         print("⚠️ Warning: Groq predicted action for element ID \(id), but element not found in current DOM.")
                    }
                } else if predictedActionString?.contains("none") == true {
                    // Handle none action explicitly
                    actionType = "none"
                    elementId = nil // No element associated with none
                    predictedElement = nil
                }

                // Find the DOM element if an ID was extracted and action is not none
                 if let id = elementId, actionType != "none" {
                    // --- Add logging for thedom keys ---
                    print("Looking for ID \(id) in thedom keys: \(thedom.keys.sorted())")
                    // --- End logging ---
                    predictedElement = dom.values.first { $0.clickableId == id }
                    if predictedElement == nil {
                         print("⚠️ Warning: Groq predicted action for element ID \(id), but element not found in current DOM.")
                    }
                }
                
            } else {
                print("Error: Could not parse Groq JSON response structure")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw Response: \(responseString)")
                }
            }
        } catch {
            print("Error parsing Groq JSON response: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw Response (on parse error): \(responseString)")
            }
        }
    }
    task.resume()
    // --- End Groq API Call ---

    _ = semaphore.wait(timeout: .now() + 30) // Wait up to 30 seconds for the API call

    return (predictedElement, predictedActionString)
}
