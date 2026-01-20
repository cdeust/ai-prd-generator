import Foundation

/// Generic prompt builder for vision analysis
/// Used by all vision providers to generate consistent analysis prompts
struct VisionPromptBuilder: Sendable {
    func buildAnalysisPrompt(customPrompt: String?) -> String {
        let basePrompt = buildBasePrompt()

        if let customPrompt = customPrompt {
            return "\(basePrompt)\n\nAdditional context: \(customPrompt)"
        }

        return basePrompt
    }

    private func buildBasePrompt() -> String {
        """
        Analyze this UI mockup and extract the following information in JSON format:

        {
          "screenName": "Screen name or title",
          "screenDescription": "Brief description of the screen's purpose",
          "layoutType": "list|grid|form|dashboard|detail|settings|login|profile|...",
          "components": [
            {
              "type": "button|text_field|label|image|switch|...",
              "label": "Component label or text",
              "placeholder": "Placeholder text (if applicable)",
              "position": {"x": 0, "y": 0, "width": 100, "height": 50},
              "state": "enabled|disabled|selected|focused|...",
              "isInteractive": true|false,
              "accessibilityLabel": "Accessibility description"
            }
          ],
          "interactions": [
            {
              "componentId": "Identifier of the interacted component",
              "trigger": "tap|swipe|scroll|...",
              "action": "navigate|submit|toggle|...",
              "targetScreen": "Destination screen (if navigation)",
              "feedback": {
                "visual": "highlight|scale|...",
                "haptic": "light|medium|heavy|...",
                "audio": "click|success|..."
              }
            }
          ],
          "dataRequirements": [
            {
              "fieldName": "Field name",
              "dataType": "text|email|password|number|...",
              "isRequired": true|false,
              "validation": ["minLength:8", "pattern:email"],
              "placeholder": "Placeholder text",
              "helpText": "Help or hint text"
            }
          ],
          "userFlows": [],
          "uncertainties": [
            "Areas where you are uncertain about the analysis (e.g., unclear labels, ambiguous icons)"
          ],
          "suggestedClarifications": [
            "Questions to ask to clarify unclear aspects of the mockup"
          ]
        }

        Focus on extracting all interactive elements, form fields, and navigation patterns.
        Be honest about uncertainties and suggest clarifying questions when needed.
        """
    }
}

