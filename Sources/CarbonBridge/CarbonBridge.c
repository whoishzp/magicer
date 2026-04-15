#include "include/CarbonBridge.h"
#include <Carbon/Carbon.h>
#include <stddef.h>

static MGHotkeyCallback g_callback = NULL;

// Stores up to 32 hot key refs indexed by the handle we return (1-based).
static EventHotKeyRef g_hotKeyRefs[32] = {NULL};

static OSStatus hotKeyHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData) {
    (void)nextHandler; (void)userData;
    EventHotKeyID keyID = {0, 0};
    GetEventParameter(event, kEventParamDirectObject,
                      typeEventHotKeyID, NULL,
                      sizeof(EventHotKeyID), NULL, &keyID);
    if (g_callback != NULL) {
        g_callback((MGHotkeyID)keyID.id);
    }
    return noErr;
}

int mg_install_hotkey_handler(MGHotkeyCallback callback) {
    g_callback = callback;

    EventTypeSpec eventType = {kEventClassKeyboard, kEventHotKeyPressed};
    EventHandlerRef handlerRef = NULL;
    OSStatus status = InstallApplicationEventHandler(
        NewEventHandlerUPP(hotKeyHandler),
        1, &eventType, NULL, &handlerRef);
    return (int)status;
}

uint32_t mg_register_hotkey(uint16_t keyCode, uint32_t carbonModifiers, MGHotkeyID hotkeyID) {
    if (hotkeyID == 0 || hotkeyID > 31) return 0;

    // Unregister any existing registration for this ID slot.
    if (g_hotKeyRefs[hotkeyID] != NULL) {
        UnregisterEventHotKey(g_hotKeyRefs[hotkeyID]);
        g_hotKeyRefs[hotkeyID] = NULL;
    }

    EventHotKeyID carbonID = {'MGKB', hotkeyID};
    EventHotKeyRef ref = NULL;
    OSStatus status = RegisterEventHotKey(
        (UInt32)keyCode, carbonModifiers, carbonID,
        GetApplicationEventTarget(), 0, &ref);

    if (status == noErr && ref != NULL) {
        g_hotKeyRefs[hotkeyID] = ref;
        return hotkeyID;   // use ID as handle
    }
    return 0;
}

void mg_unregister_hotkey(uint32_t handle) {
    if (handle == 0 || handle > 31) return;
    if (g_hotKeyRefs[handle] != NULL) {
        UnregisterEventHotKey(g_hotKeyRefs[handle]);
        g_hotKeyRefs[handle] = NULL;
    }
}
