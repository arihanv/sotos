// Predictor.swift
import Foundation
import AppKit

var maxPastUserActions = 10
var pastUserActions = [String]()
var thedom: [Int: DOMElement] = [:]

func predictDomElement(dom: [Int: DOMElement], dom_str: String) -> DOMElement? {
    thedom = dom

    let url = URL(string: "https://c723-171-66-11-52.ngrok-free.app/run_program")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    // Convert arrays to JSON strings to fit in the dictionary
    let pastActionsJson = try! JSONSerialization.data(withJSONObject: pastUserActions)
    let pastActionsString = String(data: pastActionsJson, encoding: .utf8) ?? "[]"
    
    let frontAppInfo = getFrontApp()
    let frontAppJson = try! JSONSerialization.data(withJSONObject: frontAppInfo)
    let frontAppString = String(data: frontAppJson, encoding: .utf8) ?? "[]"
    
    let actionsArray = [
        "open_app(bundle_id) - Open app",
        "click_element(id) - Click on element",
        "type_in_element(id, text) - Type text into element"
    ]
    let actionsJson = try! JSONSerialization.data(withJSONObject: actionsArray)
    let actionsString = String(data: actionsJson, encoding: .utf8) ?? "[]"

    let body: [String: String] = [
        "past_user_actions": pastActionsString,
        "open_application": frontAppString,
        "current_state": dom_str,
        "actions": actionsString
    ]
    
    request.httpBody = try! JSONSerialization.data(withJSONObject: body)

    var predictedElement: DOMElement? = nil
    let semaphore = DispatchSemaphore(value: 0)

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        guard let data = data else {
            print("Output action: No data received")
            return
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("Output action: Could not parse JSON")
            return
        }
        print("Output action: \(json)")
        // Handle output_action as either String or Dictionary
        if let outputAction = json["output_action"] as? String {
            print("Output action: \(outputAction)")
            if outputAction.contains("click_element") {
                if let elementIdStr = extractValue(from: outputAction, key: "id"), let elementId = Int(elementIdStr) {
                    if let element = dom.values.first(where: { $0.clickableId == elementId }) {
                        predictedElement = element
                        return
                    }
                }
            }
        } else if let outputActionDict = json["output_action"] as? [String: Any] {
            // e.g., {"type_in_element": {"id": 34, "text": "..."}}
            if let (action, params) = outputActionDict.first {
                var actionString = action
                if let paramDict = params as? [String: Any] {
                    let paramString = paramDict.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
                    actionString += "(" + paramString + ")"
                }
                print("Output action (dict): \(actionString)")
                if action == "click_element" || action == "type_in_element" {
                    if let idValue = (params as? [String: Any])?["id"], let elementId = (idValue as? Int) ?? Int("\(idValue)") {
                        if let element = dom.values.first(where: { $0.clickableId == elementId }) {
                            predictedElement = element
                            return
                        }
                    }
                }
            }
        } else {
            print("Output action: No output_action")
            return
        }
    }
    task.resume()
    semaphore.wait()
    
    if let element = predictedElement {
        return element
    } else {
        return nil
    }
}

// Helper to append and trim pastUserActions
private func appendPastUserAction(_ action: String) {
    pastUserActions.append(action)
    if pastUserActions.count > maxPastUserActions {
        pastUserActions = Array(pastUserActions.suffix(maxPastUserActions))
    }
}

func execute_actions(past_actions: [String], actions: [String]) -> (Bool, [String]) {
    var task_completed = false
    
    print("Executing actions: \(actions)")

    for action in actions {
        if action.contains("open_app") {
            // Parse bundle_id from action string
            if let bundleId = extractValue(from: action, key: "bundle_id") {
                do {
                    try openApplication(bundleId: bundleId)
                    appendPastUserAction("✅ Opened app: \(bundleId)")
                } catch {
                    appendPastUserAction("❌ [FAILED] Opened app: \(bundleId)")
                }
            }
        } else if action.contains("click_element") {
            if let elementIdStr = extractValue(from: action, key: "id"), let elementId = Int(elementIdStr) {
                do {
                    print("!clicking element \(elementId)")
                    try clickElement(dom: thedom, clickableId: elementId)
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
                    
                    // Type the text
                    for char in text {
                        let keyCode = CGKeyCode(char.unicodeScalars.first!.value)
                        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
                        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
                        keyDown?.post(tap: .cghidEventTap)
                        keyUp?.post(tap: .cghidEventTap)
                        Thread.sleep(forTimeInterval: 0.01) // Small delay between keystrokes
                    }
                    
                    appendPastUserAction("✅ Typed text: \(text) into element: \(elementId)")
                } catch {
                    appendPastUserAction("❌ [FAILED] Typing text: \(text) into element: \(elementId) - \(error.localizedDescription)")
                }
            }
        } else if action.contains("hotkey") {
            if let keys = extractValue(from: action, key: "keys") {
                // Implement hotkey functionality
                appendPastUserAction("✅ Pressed keys: \(keys)")
            }
        } else if action.contains("wait") {
            if let secondsStr = extractValue(from: action, key: "seconds"), let seconds = Double(secondsStr) {
                Thread.sleep(forTimeInterval: seconds)
                appendPastUserAction("✅ Waited \(seconds) sec")
            }
        } else if action.contains("finish") {
            task_completed = true
            appendPastUserAction("Task completed")
        }
    }
    
    return (task_completed, pastUserActions)
}

// Helper function to extract values from action strings
private func extractValue(from action: String, key: String) -> String? {
    // Handle both formats:
    // 1. key="value" or key='value'
    // 2. key=value
    // 3. key(value) format from dictionary conversion
    
    // Try quoted format first: key="value" or key='value'
    let quotedPattern = "\(key)\\s*=\\s*[\"']([^\"']*)[\"']"
    if let match = try? NSRegularExpression(pattern: quotedPattern, options: []).firstMatch(
        in: action, options: [], range: NSRange(location: 0, length: action.count)),
       let range = Range(match.range(at: 1), in: action) {
        return String(action[range])
    }
    
    // Try unquoted format: key=value
    let unquotedPattern = "\(key)\\s*=\\s*([^,\\s\\)]+)"
    if let match = try? NSRegularExpression(pattern: unquotedPattern, options: []).firstMatch(
        in: action, options: [], range: NSRange(location: 0, length: action.count)),
       let range = Range(match.range(at: 1), in: action) {
        return String(action[range])
    }
    
    // Try parentheses format: key(value)
    let parenthesesPattern = "\(key)\\s*\\(\\s*([^,\\)]+)"
    if let match = try? NSRegularExpression(pattern: parenthesesPattern, options: []).firstMatch(
        in: action, options: [], range: NSRange(location: 0, length: action.count)),
       let range = Range(match.range(at: 1), in: action) {
        return String(action[range])
    }
    
    return nil
}

// Returns (predicted DOMElement, predicted action string)
func predictDomElementWithAction(dom: [Int: DOMElement], dom_str: String) -> (DOMElement?, String?) {
    thedom = dom

    let url = URL(string: "https://c723-171-66-11-52.ngrok-free.app/run_program")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let pastActionsJson = try! JSONSerialization.data(withJSONObject: pastUserActions)
    let pastActionsString = String(data: pastActionsJson, encoding: .utf8) ?? "[]"
    let frontAppInfo = getFrontApp()
    let frontAppJson = try! JSONSerialization.data(withJSONObject: frontAppInfo)
    let frontAppString = String(data: frontAppJson, encoding: .utf8) ?? "[]"
    let actionsArray = [
        "open_app(bundle_id) - Open app",
        "click_element(id) - Click on element",
        "type_in_element(id, text) - Type text into element"
    ]
    let actionsJson = try! JSONSerialization.data(withJSONObject: actionsArray)
    let actionsString = String(data: actionsJson, encoding: .utf8) ?? "[]"

    let body: [String: String] = [
        "past_user_actions": pastActionsString,
        "open_application": frontAppString,
        "current_state": dom_str,
        "actions": actionsString
    ]
    request.httpBody = try! JSONSerialization.data(withJSONObject: body)

    var predictedElement: DOMElement? = nil
    var predictedAction: String? = nil
    let semaphore = DispatchSemaphore(value: 0)

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        guard let data = data else { return }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        if let outputAction = json["output_action"] as? String {
            predictedAction = outputAction
            if outputAction.contains("click_element") {
                if let elementIdStr = extractValue(from: outputAction, key: "id"), let elementId = Int(elementIdStr) {
                    if let element = dom.values.first(where: { $0.clickableId == elementId }) {
                        predictedElement = element
                        return
                    }
                }
            }
        } else if let outputActionDict = json["output_action"] as? [String: Any] {
            if let (action, params) = outputActionDict.first {
                var actionString = action
                if let paramDict = params as? [String: Any] {
                    let paramString = paramDict.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
                    actionString += "(" + paramString + ")"
                }
                predictedAction = actionString
                if action == "click_element" || action == "type_in_element" {
                    if let idValue = (params as? [String: Any])?["id"], let elementId = (idValue as? Int) ?? Int("\(idValue)") {
                        if let element = dom.values.first(where: { $0.clickableId == elementId }) {
                            predictedElement = element
                            return
                        }
                    }
                }
            }
        }
    }
    task.resume()
    semaphore.wait()
    return (predictedElement, predictedAction)
}

// func predictDomElement(dom: [Int: DOMElement], dom_str: String) -> DOMElement {
//     let clickableElements = dom.values.filter { $0.isClickable } 
//     if let randomElement = clickableElements.randomElement() {
//         return randomElement
//     }
//     return dom.values.randomElement() ?? dom[0]!
// }
// func predictDomElement(dom: [Int: DOMElement], dom_str: String) -> DOMElement {
//     let api_key = "AIzaSyBuJ6B4R905oXUVnj1oaQ_Nsb5DzcmaZUs"
//     let url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"
    
//     let system_prompt = "You are a helpful assistant that can predict the next action to click on.
    
//     2. click_element(id) - Click on element
// 3. type_in_element(id, text) - Type text into element
//     "
    
//     request_body = {
//         "contents": [{"role": "user", "parts": [{"text": prompt}]}],
//         "generationConfig": {"temperature": 1, "topK": 40, "topP": 0.95, "maxOutputTokens": 4192},
//         "systemInstruction": {
//             "parts": [
//                 {"text": system_prompt}
//             ]
//         }
//     }
    
//     response = requests.post(url, json=request_body)
//     data = response.json()
//     candidates = data.get("candidates", [])
//     text = candidates[0]["content"]["parts"][0]["text"] if candidates else ""
    
//     # Clean response
//     if "```json" in text:
//         text = text.split("```json", 1)[1]
//     text = text.replace("```", "").strip()
//     if "{" in text and "}" in text:
//         start_idx = text.find("{")
//         end_idx = text.rfind("}") + 1
//         text = text[start_idx:end_idx].strip()

//     try:
//         response_json = json.loads(text, strict=False) # allows \t and other chars which could cause issues
//         actions = response_json.get("actions", [])
//         current_state = response_json.get("current_state", {
//             "evaluation_previous_goal": "Unknown",
//             "memory": "No memory available",
//             "next_goal": "No goal specified"
//         })
//     except Exception as e:
//         print(f"Error parsing JSON: {e}, text: {text}")
//         actions = []
//         current_state = {
//             "evaluation_previous_goal": "Unknown",
//             "memory": "No memory available",
//             "next_goal": "No goal specified"
//         }
// }
