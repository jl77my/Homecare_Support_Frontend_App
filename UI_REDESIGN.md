# HomeCare UI redesign

This project applies the supplied mobile UI boards to the existing Flutter application while preserving the original providers, services, models, API calls, and role permissions.

## Screen mapping

- Authentication: role choice, account creation, and sign in
- Elderly: connected and not-connected home states, SOS, reminders, mood logging, invitation code, care connections, and profile
- Caregiver: care overview and vital logging, tasks, reminders, reports with photos, conversations, pairing, account settings, and AI assistant
- Family: wellbeing overview, tasks, reminders, reports, conversations, family pairing, account settings, and care connections
- Global states: medication reminder and emergency overlays

## Deliberately omitted reference-only actions

The redesign does not add UI for actions that have no implementation in the current app, including password recovery, reminder snoozing/skipping, direct emergency calling, account deletion, language switching, notification preference toggles, or help/support tickets.

## Design system

- Navy headings, accessible blue primary actions, green success states, red emergency/destructive states
- White cards on a pale blue background with restrained borders and elevation
- 4/8dp spacing rhythm, minimum 48dp touch targets, safe-area-aware bottom navigation
- Role-aware navigation with no more than five primary destinations
- Vector Material icons only; no emoji icons
- Responsive content width for phones, landscape layouts, and tablets
