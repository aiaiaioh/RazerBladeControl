//! Low-level keyboard hook that remaps the F1–F12 row to media/volume keys
//! when "media default" is enabled. Runs inside the daemon on a dedicated
//! thread with its own message loop, which WH_KEYBOARD_LL requires.
//!
//! Unlike a Raw Input sink, a low-level hook can *suppress* the original
//! key, so an F-key is genuinely replaced by its media action rather than
//! firing both.

use std::ptr::null_mut;
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread;

use winapi::ctypes::c_int;
use winapi::shared::minwindef::{LPARAM, LRESULT, WPARAM};
use winapi::um::libloaderapi::GetModuleHandleW;
use winapi::um::winuser::{
    CallNextHookEx, DispatchMessageW, GetMessageW, SendInput, SetWindowsHookExW, TranslateMessage,
    HC_ACTION, INPUT, INPUT_KEYBOARD, KBDLLHOOKSTRUCT, KEYEVENTF_KEYUP, LLKHF_INJECTED, MSG, VK_F1,
    VK_F10, VK_F11, VK_F12, VK_F2, VK_F3, VK_F7, VK_F8, VK_F9, WH_KEYBOARD_LL, WM_KEYDOWN,
    WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP,
};

// Media / volume virtual-key codes. Defined locally as u16 (the type of
// KEYBDINPUT.wVk) to avoid winapi version differences and repeated casts.
const VK_VOLUME_MUTE: u16 = 0xAD;
const VK_VOLUME_DOWN: u16 = 0xAE;
const VK_VOLUME_UP: u16 = 0xAF;
const VK_MEDIA_NEXT_TRACK: u16 = 0xB0;
const VK_MEDIA_PREV_TRACK: u16 = 0xB1;
const VK_MEDIA_PLAY_PAUSE: u16 = 0xB3;

static MEDIA_DEFAULT: AtomicBool = AtomicBool::new(false);

pub fn set_media_default(val: bool) {
    MEDIA_DEFAULT.store(val, Ordering::Relaxed);
}

pub fn get_media_default() -> bool {
    MEDIA_DEFAULT.load(Ordering::Relaxed)
}

/// Install the low-level keyboard hook on a dedicated thread. The hook is
/// always installed; it only remaps keys while `MEDIA_DEFAULT` is true, so the
/// toggle costs essentially nothing when off.
pub fn start_media_key_hook() {
    thread::spawn(|| unsafe {
        let hook = SetWindowsHookExW(
            WH_KEYBOARD_LL,
            Some(keyboard_hook_proc),
            GetModuleHandleW(null_mut()),
            0,
        );
        if hook.is_null() {
            // Hook failed to install; nothing for this thread to do.
            return;
        }

        // WH_KEYBOARD_LL delivers callbacks via the installing thread's message
        // queue, so this thread must pump messages or the hook never fires.
        let mut msg: MSG = std::mem::zeroed();
        while GetMessageW(&mut msg, null_mut(), 0, 0) > 0 {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    });
}

/// Map an F-row virtual-key code to the media key it should emit. Returns
/// `None` for keys with no SendInput equivalent (F4 mic-mute, F5/F6
/// brightness), which are then passed through unchanged.
fn map_fkey_to_media(vk: u32) -> Option<u16> {
    match vk as c_int {
        VK_F1 => Some(VK_VOLUME_MUTE),
        VK_F2 => Some(VK_VOLUME_DOWN),
        VK_F3 => Some(VK_VOLUME_UP),
        VK_F7 => Some(VK_MEDIA_PLAY_PAUSE),
        VK_F8 => Some(VK_MEDIA_NEXT_TRACK),
        VK_F9 => Some(VK_MEDIA_PREV_TRACK),
        VK_F10 => Some(VK_MEDIA_PLAY_PAUSE),
        VK_F11 => Some(VK_VOLUME_DOWN),
        VK_F12 => Some(VK_VOLUME_UP),
        _ => None,
    }
}

unsafe extern "system" fn keyboard_hook_proc(
    code: c_int,
    wparam: WPARAM,
    lparam: LPARAM,
) -> LRESULT {
    if code == HC_ACTION && MEDIA_DEFAULT.load(Ordering::Relaxed) {
        let kb = &*(lparam as *const KBDLLHOOKSTRUCT);

        // Skip events we injected ourselves, or we would re-process the media
        // keys we emit and loop forever.
        if kb.flags & LLKHF_INJECTED == 0 {
            if let Some(media_vk) = map_fkey_to_media(kb.vkCode) {
                let msg = wparam as u32;
                let is_down = msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN;
                let is_up = msg == WM_KEYUP || msg == WM_SYSKEYUP;

                // Emit on press (auto-repeat naturally ramps held volume keys),
                // and swallow both the down and up of the original F-key so it
                // never reaches the focused application.
                if is_down {
                    send_media_key(media_vk);
                }
                if is_down || is_up {
                    return 1;
                }
            }
        }
    }

    CallNextHookEx(null_mut(), code, wparam, lparam)
}

unsafe fn send_media_key(vk: u16) {
    let mut inputs: [INPUT; 2] = std::mem::zeroed();

    inputs[0].type_ = INPUT_KEYBOARD;
    {
        let ki = inputs[0].u.ki_mut();
        ki.wVk = vk;
        ki.dwFlags = 0; // key down
    }

    inputs[1].type_ = INPUT_KEYBOARD;
    {
        let ki = inputs[1].u.ki_mut();
        ki.wVk = vk;
        ki.dwFlags = KEYEVENTF_KEYUP;
    }

    SendInput(
        2,
        inputs.as_mut_ptr(),
        std::mem::size_of::<INPUT>() as c_int,
    );
}
