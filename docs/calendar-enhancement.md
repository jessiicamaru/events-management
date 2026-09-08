# Calendar Enhancement Plan

> Re-architect the Flutter calendar UI to match the modern Shadcn 'big-calendar' React component.

## 1. Goal

Bring the elegant, highly functional UI of the React `big-calendar` component into our Flutter `habit-tracker` application using `syncfusion_flutter_calendar` and `shadcn_ui`.

## 2. Technical Context

- **Current Architecture**: We use `SfCalendar` with a basic configuration and solid event blocks.
- **Target Architecture**: We need a deeply customized `SfCalendar` utilizing its internal builders (`appointmentBuilder`, `monthCellBuilder`) combined with `shadcn_ui` components (`ShadButton`, `ShadDialog`, `ShadPopover`, `ShadSelect`).
- **State Management**: We will use Riverpod to manage the selected View (Day, Week, Month, Agenda), the selected Date (for navigation), and user filters.

## 3. Proposed Features & Changes

### A. Calendar Toolbar (Header)
A new top navigation bar replacing the default `SfCalendar` header.
- **Current Date Display**: Formatted gracefully (e.g. `April 2025`).
- **Navigation Controls**: `<` and `>` buttons using `ShadButton.outline(icon: LucideIcons.chevronLeft)` and a "Today" button.
- **View Switcher**: A segmented control using grouped `ShadButton` (or a `ShadSelect` on mobile) to toggle between `Day`, `Week`, `Month`, and `Agenda`.
- **Add Event**: A primary `ShadButton` with `LucideIcons.plus` to trigger a `ShadDialog` for manual event creation.

### B. Shadcn-Styled Events (`appointmentBuilder`)
Instead of default solid rectangles, events will have:
- A transparent background with a 10% opacity tint of the habit's category color.
- A solid 3px left-border matching the category color.
- Modern typography using `theme.textTheme.small` for time and title.
- Support for "Happening Now" pulsing indicators (micro-animations).
- Three badge display variants (dot, colored, mixed) configurable via settings.

### C. Drag & Drop Side Panel
- The current bottom "Unscheduled Habits" list will be moved to a collapsible Right Side Panel (on Desktop/Tablet) or a bottom Drawer/Sheet on mobile.
- Support filtering these habits by category using `ShadSelect`.

### D. Settings & Customization
- A "Calendar settings" dropdown `ShadPopover` at the bottom left (or top right) to configure:
  - Working hours
  - Visible hour ranges
  - Badge style variants

## 4. Phase Breakdown

**Phase 1: Header & State**
- Extract `CalendarToolbar` into a separate widget.
- Connect `SfCalendar` controller to Riverpod variables (`selectedDate`, `calendarView`).
- Implement Custom Header and disable `SfCalendar`'s native header.

**Phase 2: Event Styling (appointmentBuilder)**
- Create `ShadEventCard` widget.
- Implement `appointmentBuilder` to return `ShadEventCard`.
- Map Habit Categories to a fixed, modern Tailwind-like color palette (e.g., slate, red, amber, emerald).

**Phase 3: Drag & Drop & Form**
- Relocate the Drag & Drop habit list to a side panel.
- Implement `AddEventDialog` using `ShadDialog` and `ShadForm`.

## 5. Verification Plan
- **Automated Tests**: Update `events_provider_test.dart` if state management changes.
- **Manual Verification**: Run Flutter on Windows and Web to test Drag & Drop precision and UI responsiveness. Ensure dark mode correctly adapts the event background tints.

## 🔴 User Review Required

> [!WARNING]
> Please review the following design decisions before we proceed:

1. **Calendar Views**: Do you want to support all 4 views (`Day`, `Week`, `Month`, `Agenda`), or just limit it to `Week` and `Month` to keep it simple initially?
2. **Color Palette**: Should we enforce a fixed Tailwind-style color palette for Habit categories (e.g. `blue`, `green`, `red`, `amber`, `purple`, `slate`) to ensure the UI looks consistent and modern like Shadcn?
3. **Mobile Layout**: For mobile screens, the Drag & Drop list on the right side might be too cramped. Should we use a Bottom Sheet for unscheduled habits on mobile devices?
