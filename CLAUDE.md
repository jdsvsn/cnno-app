# CNNO Mobile App (TMA3084 Group 19, "Cinnamon Codes")

Flutter app for CNNO, a cinnamon roll business (client: Patricia Giring, founder). UNIMAS TMA3084 Software Engineering Lab group project. Team leader: Jude Paru Laurence.
Read this file first, then docs/ when you need detail. Full requirements are in docs/SRS.md. Never invent requirements: if something is not here or in docs/, ask.

## Deadlines
- M2 (Week 9, 16 to 22 Nov 2026, 15%): SRS, a video explaining the SRS, and a 1 to 2 minute video of an early Flutter app version. Figma is required for the UI design.
- M3 Project Evaluation (Week 13, 25%) and M4 Testing and Release (10%) follow. See docs/assessment.pdf.

## Stack (fixed by course rules and the proposal)
- Flutter and Dart 3+, Material Design 3, Android 8.0+ (API 26+) only. State management: Provider.
- Firebase: Authentication (email and password, FR-01), Cloud Firestore, Cloud Storage (product photos), Cloud Functions.
- Generative AI: Gemini API, called only through Cloud Functions. API keys and passwords must never be in the app or the repository.
- Roles: customer and admin, same app. Firestore security rules must refuse admin actions for customers.
- Course rule: significant AI-assisted work must be recorded in LOGAI and linked to the feature and the GitHub pull request. Work from GitHub Issues, one per requirement ID. Keep a short LOGAI entry for anything you generate.

## Business rules and decisions (agreed with the client)
- Order statuses, in order: Pending, Being prepared, Ready for pickup, Out for delivery (delivery orders only), Completed.
- Customers choose pickup or delivery and a preferred pre-order date. Delivery is booked by CNNO on Grab outside the app, fee quoted separately.
- Payment is outside the app. There is no online payment gateway. The app records the payment method only.
- After checkout the customer gets an email receipt (products, quantities, total, details).
- Prices are in RM. Gula Apong was REMOVED by the client. Do not add it anywhere.

## Final menu and prices
Single rolls: OG Cinnamon RM 8, Chocolate RM 10, Pistachio RM 11.
- OG: "The OG." Soft, fluffy roll filled with buttery cinnamon sugar, topped with smooth cream cheese frosting and a dusting of cinnamon.
- Chocolate: "For the choco lovers." Rich chocolate roll filled with milk chocolate, topped with silky chocolate frosting and chocolate chips.
- Pistachio: "Crave some nuts?" Buttery soft roll filled with creamy pistachio sauce, topped with pistachio frosting and crushed pistachio nuts.
Baby Rolls (box): OG RM 14, Choco RM 16, Pista RM 17.
Duo Box: OG+OG RM 15, Choco+Choco RM 19, Pista+Pista RM 20, OG+Choco RM 17, OG+Pista RM 18, Choco+Pista RM 20.
Party Box: OG RM 54, Choco RM 63, Pista RM 72.
Seed Firestore with this data. Admin can change prices and availability (FR-11). Brand text: "cnno's bakes".

## Requirements (IDs must match the proposal and SRS)
| ID | Name | Module | Priority | Owner |
|---|---|---|---|---|
| FR-01 | Register and log in | User Management | Must | Jude |
| FR-02 | Admin login | Admin Access | Must | Deanne |
| FR-03 | Browse catalogue | Product Catalogue | Must | Izwan |
| FR-04 | Show flavour availability | Product Catalogue | Must | Izwan |
| FR-05 | Add items to cart | Cart and Checkout | Must | Izwan |
| FR-06 | Check out and choose payment method | Cart and Checkout | Must | Jude |
| FR-07 | Select preferred preorder date | Preorder and Fulfilment | Must | Jude |
| FR-08 | Choose pickup or delivery | Preorder and Fulfilment | Must | Jude |
| FR-09 | Track order status | Order Tracking | Must | Izwan |
| FR-10 | Email receipt | Receipt Email | Must | Eizwandie |
| FR-11 | Manage products, prices and availability | Admin Dashboard | Must | Deanne |
| FR-12 | View orders and update status | Admin Dashboard | Must | Deanne |
| FR-13 | View orders by date and method | Admin Dashboard | Must | Deanne |
| FR-14 | View past orders | Order Tracking | Should | Danish |
| FR-15 | Order status notification | Order Tracking | Could | Danish |
| FR-AI-01 | Smart Recommendation | AI Feature | Must | Eizwandie |
| FR-AI-02 | Order Assistant | AI Feature | Must | Eizwandie |
Non-functional requirements NFR-01 to NFR-06 are in docs/SRS.md section 3.4. FR-AI-01 Smart Recommendation and FR-AI-02 Order Assistant are described in section 3.3.

## AI rules (client requirements)
- Answers about products, prices and availability must come from the Firestore menu data, never from model memory. Never invent prices or promise things CNNO cannot do.
- If the assistant is not confident, it tells the customer to contact CNNO.
- Smart Recommendation suggests another flavour from the customer's preferences or past orders.

## Design (Figma is the source of truth for layout)
- Figma file: https://www.figma.com/design/gWedOhktcfmGHpAmHoSVoM (9 screens, 390x844). Screenshots of some screens are in assets/figma/.
- Screens: UI-01 Login and Register (FR-01, FR-02); UI-02 Menu with AI recommendation (FR-03, FR-04, FR-AI-01); UI-03 Product detail (FR-03, FR-04, FR-05); UI-04 Cart (FR-05); UI-05 Checkout and pre-order (FR-06, FR-07, FR-08); UI-06 Order status (FR-09, FR-14, FR-15); UI-07 AI Order Assistant (FR-AI-02); UI-08 Admin orders (FR-12, FR-13); UI-09 Admin products (FR-11).
- The "Continue with Google" button in the login mockup is NOT a requirement. Build email and password login only unless Jude says otherwise.
- Customer bottom navigation: Menu, Cart, Orders, Assistant, Profile. Admin: Orders, Products (plus Reports and Settings placeholders).
- Theme requested by the client: red and maroon (not the earlier brown and beige). Colours used in the mockup: primary red #A3162F, deep maroon #7A1126, stripe red #C42D4A, background #FFF7F5, text #5A0F20, soft pink #F8E1E5, muted text #8C6B71, available green #5E7A3F. The top of screens has a striped awning band in the three reds.
- Use the client's real photos and logo in assets/ (transparent PNGs). Do not use stock images.
- Fonts: the client asked for minor font changes in the 5 Nov meeting. Not decided yet. Ask before choosing a font. The mockup uses Inter as a placeholder.
- Order status is always shown as text, not only colour.

## Client meetings (details in docs/SRS.md Appendix A)
16 Oct Google Meet interview. 22 Oct proposal and app structure approved. 29 Oct initial design shown, client wanted her own pictures, red and maroon theme, minor layout changes, Gula Apong removed. 5 Nov latest design approved, minor font and picture changes requested.

## Still open (ask Jude, do not guess)
Lead time for pre-orders (proposed 1 day), CNNO phone number for delivery, accepted payment methods list, cancellation rule, font choice, GitHub issue numbers.

## Files
- docs/SRS.md, docs/Proposal.md: full text. docs/original/ has the Word and PDF files.
- docs/client_interview.txt: transcript of the first client interview.
- docs/assessment.pdf: course assessment brief.
- assets/: logo and product photos (transparent PNG).
