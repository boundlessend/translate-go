#include <ApplicationServices/ApplicationServices.h>
#include <unistd.h>

static void post_key(CGKeyCode key_code, CGEventFlags flags) {
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
    CGEventRef key_down = CGEventCreateKeyboardEvent(source, key_code, true);
    CGEventRef key_up = CGEventCreateKeyboardEvent(source, key_code, false);

    CGEventSetFlags(key_down, flags);
    CGEventSetFlags(key_up, flags);
    CGEventPost(kCGHIDEventTap, key_down);
    CGEventPost(kCGHIDEventTap, key_up);

    CFRelease(key_down);
    CFRelease(key_up);
    CFRelease(source);
}

int main(void) {
    usleep(500000);
    post_key(0, kCGEventFlagMaskCommand);
    usleep(200000);
    post_key(8, kCGEventFlagMaskControl);
    return 0;
}
