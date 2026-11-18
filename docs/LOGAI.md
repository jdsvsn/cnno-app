# LOGAI: AI-assisted work log

Course rule: significant AI-assisted work is recorded here and linked to the feature and the GitHub pull request or commit.

| Date | Tool | Feature / FR | What AI produced | Human review | PR / commit |
|---|---|---|---|---|---|
| 2026-11-18 | Claude Code (Claude Opus 5.5) | FR-01 to FR-14, FR-AI-01, FR-AI-02 (early version for M2) | Flutter project structure, models, Provider state, Firebase services, all 9 screens from the Figma mockup, Firestore and Storage rules, Cloud Functions (Gemini recommendation and assistant, email receipt), unit tests for business rules | Jude: reviewed against CLAUDE.md, SRS and Figma; ran `flutter analyze` and `flutter test` | Initial app commit |

## Notes on AI design (FR-AI-01, FR-AI-02)

- Gemini is called only from Cloud Functions. The key is in Secret Manager (`GEMINI_API_KEY`).
- Product, price and availability answers come from the Firestore `products` collection, sent to the model on every request. The prompt forbids inventing prices or promises (BR-09).
- If the model is not confident, fails or is unavailable, the assistant answers: "I am not sure about that one. Please contact CNNO directly and they will help you."
- Only flavour preferences and product names are sent for recommendations. No names, emails or phone numbers (PDPA 2010).
- Daily limit of 50 AI calls per user (`aiUsage` collection).
