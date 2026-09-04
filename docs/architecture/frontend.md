# Frontend Architecture

React application:

src/
├── app/
├── pages/
├── features/
├── components/
├── hooks/
├── api/
└── shared/

Pages compose features.

Features contain user-facing business functionality.

API access is centralized.

Core user journeys are covered by Playwright.
