---
description: Design system guidelines based on Apple HIG - must be followed for all UI development
---

# TesseractStudio Design & Engineering System

## Development Discipline (IDE Rules)
> [!IMPORTANT]
> **Component First Mentality:**
> Always prioritize creating reusable components over duplicating code. Before writing HTML/CSS repeatedly, check `CoreComponents` or create a new component.
> - **DRY (Don't Repeat Yourself):** If you write the same class list or HTML structure twice, refactor it into a component.
> - **Centralized Styling:** Changes to design should happen in ONE place (the component), not 50 places (in templates).
> - **CoreComponents:** Maintain `lib/tesseract_studio_web/components/core_components.ex` as the source of truth for UI elements.

## Design Principles (Apple HIG Based)

### Core Values
1. **Clarity** - Interfaces must be legible, precise, and easy to understand
2. **Deference** - UI helps users focus on content by minimizing visual clutter
3. **Depth** - Visual layers and motion convey hierarchy

---

## Visual Design Rules

### Colors
- Use semantic colors: blue for actions, red for destructive, green for success
- Maintain 4.5:1 contrast ratio for text, 3:1 for non-text elements
- Always test in both light and dark modes
- Primary brand colors: `#3b82f6` (blue), `#1e293b` (dark), `#1c1c1d` (darker)

### Typography
- Use system fonts (Inter for web, SF Pro for native)
- Font sizes:
  - Titles: 17-34pt (Medium weight)
  - Body: 17pt standard, 15pt secondary
  - Minimum: 11pt
- Support Dynamic Type scaling

### Layout & Spacing
- Use 8pt baseline grid for alignment
- Minimum touch targets: 44x44 points
- Respect safe areas (avoid notches, home indicators)
- Use white space strategically - don't overcrowd

### Icons
- Use consistent icon style (outlined, minimalist)
- Always pair icons with labels for clarity
- Match system icon conventions

### Motion & Animations
- Use subtle animations to reinforce spatial relationships
- Keep animations under 0.5s
- Animations must be purposeful, not decorative

---

## Navigation Rules

### Patterns
1. **Hierarchical** - General to specific (use push transitions)
2. **Flat** - Tab bars for 3-5 peer categories (always visible)
3. **Content-driven** - For browsing/exploring content

### Best Practices
- Critical content must be ≤3 taps away
- Always show back button with previous screen title
- Support edge swipes for "back" navigation
- Never hide tab bar during navigation

### Tab Bars
- Maximum 5 items
- Use icons + labels
- Don't nest tabs in modals

### Modals
- Use for focused, urgent tasks only
- Always include clear Close/Cancel option
- Don't overuse - prefer navigation

---

## User Interaction Rules

### Touch Targets
- Minimum size: 44x44 points
- Provide immediate feedback (within 100ms)

### Gestures
- **Tap** - Primary action (selecting)
- **Swipe** - Navigation or revealing options
- **Long Press** - Contextual menus (use sparingly)
- **Pinch** - Zooming
- Avoid gesture conflicts with system gestures

### Feedback
- Visual: Color changes, highlights
- Haptic: Use for confirmations (if applicable)
- Animations: Smooth transitions for state changes

### Error Handling
- Clear, plain language messages
- Suggest solutions
- Use input validation to prevent errors

---

## Accessibility Requirements

- Support VoiceOver/screen readers
- All interactive elements need descriptive labels
- Support Dynamic Type (adjustable text sizes)
- Ensure sufficient color contrast
- Don't rely solely on color to convey information

---

## Component Naming Convention

Use `ts-` prefix for custom components to avoid conflicts:
- `ts-modal-overlay`, `ts-modal-box`
- `ts-form-group`, `ts-form-input`
- `ts-btn-primary`, `ts-btn-secondary`

---

## CSS Guidelines

### Z-Index Scale
```css
--z-dropdown: 100;
--z-sticky: 200;
--z-fixed: 300;
--z-modal-backdrop: 9999;
--z-modal: 10000;
--z-tooltip: 10001;
```

### Dark Theme Colors
```css
--bg-primary: #1c1c1d;
--bg-secondary: #1e293b;
--bg-tertiary: #334155;
--text-primary: #e2e8f0;
--text-secondary: #94a3b8;
--text-muted: #64748b;
--accent-blue: #3b82f6;
--accent-green: #10b981;
--accent-red: #ef4444;
--border: #334155;
```

### Responsive Breakpoints
```css
--mobile: 640px;
--tablet: 768px;
--desktop: 1024px;
--wide: 1280px;
```

---

## Implementation Checklist

When creating any UI component, verify:

- [ ] Touch targets are ≥44px
- [ ] Colors have sufficient contrast
- [ ] Feedback is provided within 100ms
- [ ] Component works in dark mode
- [ ] Animation duration is ≤500ms
- [ ] Custom classes use `ts-` prefix
- [ ] Modal z-index is 9999+
- [ ] Navigation depth is ≤3 levels
- [ ] Error messages are clear and helpful
- [ ] Labels exist for all interactive elements
