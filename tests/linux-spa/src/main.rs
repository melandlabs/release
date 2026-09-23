use libspa::param::video::{VideoFlags, VideoFormat, VideoInfoRaw};

fn main() {
    // Exercise the Rust wrapper that failed to compile against Jammy's headers.
    let mut video = VideoInfoRaw::new();
    video.set_format(VideoFormat::RGBx);
    video.set_flags(VideoFlags::VARIABLE_FPS);
    video.set_modifier(u64::MAX);
    assert_eq!(video.format(), VideoFormat::RGBx);
    assert_eq!(video.flags(), VideoFlags::VARIABLE_FPS);
    assert_eq!(video.modifier(), u64::MAX);

    // This must load the distribution's original PipeWire library successfully.
    pipewire::init();
    let mainloop = pipewire::main_loop::MainLoopRc::new(None).unwrap();
    let _context = pipewire::context::ContextRc::new(&mainloop, None).unwrap();

    // Xvfb supplies a real X11 display, rather than a compile-only xcap check.
    let monitors = xcap::Monitor::all().unwrap();
    assert!(!monitors.is_empty());
    let image = monitors[0].capture_image().unwrap();
    assert!(image.width() > 0 && image.height() > 0);
    println!("SPA, stock PipeWire initialization, and X11 capture passed");
}
