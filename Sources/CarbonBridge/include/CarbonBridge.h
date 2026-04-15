#pragma once
#include <stdint.h>

typedef uint32_t MGHotkeyID;
typedef void (*MGHotkeyCallback)(MGHotkeyID hotkeyID);

/// Install an application-level Carbon hot key handler.
/// Returns 0 on success (noErr).
int mg_install_hotkey_handler(MGHotkeyCallback callback);

/// Register a global hot key. keyCode is the virtual key code (same as NSEvent.keyCode).
/// carbonModifiers is the Carbon modifier mask (cmdKey | controlKey | etc).
/// Returns a non-zero registration handle on success, 0 on failure.
uint32_t mg_register_hotkey(uint16_t keyCode, uint32_t carbonModifiers, MGHotkeyID hotkeyID);

/// Unregister a previously registered hot key.
void mg_unregister_hotkey(uint32_t handle);
