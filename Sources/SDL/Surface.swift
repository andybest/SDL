//
//  Surface.swift
//  SDLTests
//
//  Created by Alsey Coleman Miller on 6/6/17.
//

import CSDL2

public final class Surface {
    
    // MARK: - Properties
    
    let internalPointer: UnsafeMutablePointer<SDL_Surface>
    
    // MARK: - Initialization
    
    deinit {
        SDL_FreeSurface(internalPointer)
    }
    
    public init?(rgb size: (width: Int, height: Int),
                 depth: Int = 32,
                 mask: (red: UInt, green: UInt, blue: UInt, alpha: UInt) = (0,0,0,0)) {
        
        guard let internalPointer = SDL_CreateRGBSurface(0, CInt(size.width), CInt(size.height), CInt(depth), CUnsignedInt(mask.red), CUnsignedInt(mask.green), CUnsignedInt(mask.blue), CUnsignedInt(mask.alpha))
            else { return nil }
        
        self.internalPointer = internalPointer
    }
    
    // Get the SDL surface associated with the window.
    ///
    /// A new surface will be created with the optimal format for the window,
    /// if necessary. This surface will be freed when the window is destroyed.
    /// - Returns: The window's framebuffer surface, or `nil` on error.
    /// - Note: You may not combine this with 3D or the rendering API on this window.
    public init?(window: Window) {
        
        guard let internalPointer = SDL_GetWindowSurface(window.internalPointer)
            else { return nil }
        
        self.internalPointer = internalPointer
    }
    
    // MARK: - Accessors
    
    public var width: Int {
        
        return Int(internalPointer.pointee.w)
    }
    
    public var height: Int {
        
        return Int(internalPointer.pointee.h)
    }
    
    public var pitch: Int {
        
        return Int(internalPointer.pointee.pitch)
    }
    
    internal var mustLock: Bool {
        
        // #define SDL_MUSTLOCK(S) (((S)->flags & SDL_RLEACCEL) != 0)
        @inline(__always)
        get { return internalPointer.pointee.flags & UInt32(SDL_RLEACCEL) != 0 }
    }
    
    // MARK: - Methods
    
    /// Get a pointer to the data of the surface, for direct inspection or modification.
    public func withUnsafeMutableBytes<Result>(_ body: (UnsafeMutableRawPointer) throws -> Result) rethrows -> Result? {
        
        let mustLock = self.mustLock
        
        if mustLock {
            
            guard lock() else { return nil }
        }
        
        let result = try body(internalPointer.pointee.pixels)
        
        if mustLock {
            
            unlock()
        }
        
        return result
    }
    
    /// Sets up a surface for directly accessing the pixels.
    ///
    /// Between calls to `lock()` / `unlock()`, you can write to and read from `surface->pixels`,
    /// using the pixel format stored in `surface->format`.
    /// Once you are done accessing the surface, you should use `unlock()` to release it.
    /// Not all surfaces require locking.
    /// If `Surface.mustLock` is `false`, then you can read and write to the surface at any time,
    /// and the pixel format of the surface will not change.
    ///
    /// - Note: No operating system or library calls should be made between lock/unlock pairs,
    /// as critical system locks may be held during this time.
    internal func lock() -> Bool {
        
        return SDL_LockSurface(internalPointer) >= 0
    }
    
    internal func unlock() {
        
        SDL_UnlockSurface(internalPointer)
    }
    
    @discardableResult
    public func blit(to surface: Surface, source: SDL_Rect? = nil, destination: SDL_Rect? = nil) -> Bool {
        
        // TODO rects
        return SDL_UpperBlit(self.internalPointer, nil, surface.internalPointer, nil) >= 0
    }
}
