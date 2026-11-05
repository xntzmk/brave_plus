#ifndef CHROME_PLUS_SRC_FOCUS_WATCH_H_
#define CHROME_PLUS_SRC_FOCUS_WATCH_H_

// Watches the UI Automation focus and caches whether the focused element is a
// text-editable control (address bar, <input>, <textarea>, contenteditable).
//
// The keyboard hook must stay cheap, so the flag is maintained by a dedicated
// UIA focus-changed event handler and only read from the hook.
void StartFocusWatch();

// True when the focused element accepts text input. Also returns true while
// the watcher is not ready yet, so a missing UIA never eats typed characters.
bool IsEditableFocused();

#endif  // CHROME_PLUS_SRC_FOCUS_WATCH_H_