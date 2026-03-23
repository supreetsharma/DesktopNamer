import CoreGraphics

// Private CoreGraphics APIs for accessing macOS Spaces
// These are used by apps like Amethyst, yabai, etc.

@_silgen_name("_CGSDefaultConnection")
func CGSDefaultConnection() -> Int32

@_silgen_name("CGSGetActiveSpace")
func CGSGetActiveSpace(_ cid: Int32) -> UInt64

@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ cid: Int32) -> CFArray

@_silgen_name("CGSManagedDisplaySetCurrentSpace")
func CGSManagedDisplaySetCurrentSpace(_ cid: Int32, _ displayRef: CFString, _ spaceID: UInt64)
