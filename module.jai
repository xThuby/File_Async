
// On Windows, MSDN states that because errors can bubble up from drivers etc, the docs can't list every possible
// error. Unhelpfully, it also lets us know that the docs for most functions won't even include a partial list. So
// some errors we return as catastrophic may be recoverable or even expected in some circumstances. On the other
// hand, some errors we report as incomplete (especially if the completed amount is zero) may be unrecoverable or
// indicate other larger issues with the system; exactly the kinds of errors that we would like to return catastrophic
// for. Thus it would be appreciated if any logging would include the platform_code so that in those cases, we can
// update the error handling. Linux and macOS list all possible errors on the man pages but some are historical
// and supposedly not returned by modern versions of either OS. But just in case (and in case they break the
// standard and return something weird anyway) it would be great to log the error codes on those platforms as well.
Error :: struct {
    code: enum {
        Success :: 0;
        DidNotWait;       // Check_only was specified on wait_for_completion and no completion was found.
        FullQueue;        // The submission queue was full so retry after waiting or calling wait_for_completion.
        FileAccessFailed; // Either the file doesn't exist, you don't have access to it, or similar.
        Incomplete;       // Not all data was read or written (file changed under you, IO error, etc).
        Catastrophic;     // Errors that should only happen in exceptional circumstances (you might assert on this).
    };
    // Errno on Unix, GetLastError on Windows. s64 can fit both types and probably any future types.
    // Use get_error_string in the System module to get the name of the error. This may be set to
    // 0 even in the case of an error if the error is not associated with a platform error code.
    platform_code: s64;
}

#if OS == .WINDOWS {
    #load "io_completion_ports.jai";
} else #if OS == .LINUX {
    // #load "thread_pool.jai"; // Uncomment to test or if you are using an old kernel. (This doesn't currently compile!)
    #load "io_uring.jai";
} else #if OS == .MACOS {
    #assert CPU == .X64 "File_Async uses several x64 #asm blocks that have no ARM64 fallbacks yet.";
    #load "thread_pool.jai";
} else {
    #assert false "File_Async only supports Windows, Linux, and macOS. Other POSIX OSs may work with thread_pool.";
}

#scope_module
error :: (code: type_of(Error.code), platform_code: $T = 0) -> Error {
    ret: Error = ---;
    ret.code = code;
    ret.platform_code = xx platform_code;
    return ret;
}
