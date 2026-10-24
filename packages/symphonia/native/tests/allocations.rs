#![expect(
    clippy::undocumented_unsafe_blocks,
    reason = "the allocator forwards to System, and the reads pass buffers the test owns"
)]

use std::alloc::{GlobalAlloc, Layout, System};
use std::cell::Cell;

use discord_luau_symphonia::{BYTES_PER_FRAME, Handle, Session, symphonia_read};

use crate::util::{ERROR_CAPACITY, Replay};

const READ_FRAMES: i32 = 960;
const STEADY_READS: usize = 20;
const FIXTURES_WITH_HEAP_FREE_DECODERS: [&str; 3] = ["tone.flac", "layout-51.flac", "tone-alac.m4a"];

struct CountingAllocator;

thread_local! {
    static ALLOCATIONS: Cell<usize> = const { Cell::new(0) };
}

#[global_allocator]
static ALLOCATOR: CountingAllocator = CountingAllocator;

unsafe impl GlobalAlloc for CountingAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        count_allocation();
        unsafe { System.alloc(layout) }
    }

    unsafe fn alloc_zeroed(&self, layout: Layout) -> *mut u8 {
        count_allocation();
        unsafe { System.alloc_zeroed(layout) }
    }

    unsafe fn realloc(&self, pointer: *mut u8, layout: Layout, new_size: usize) -> *mut u8 {
        count_allocation();
        unsafe { System.realloc(pointer, layout, new_size) }
    }

    unsafe fn dealloc(&self, pointer: *mut u8, layout: Layout) {
        unsafe { System.dealloc(pointer, layout) };
    }
}

fn count_allocation() {
    let _ = ALLOCATIONS.try_with(|count| count.set(count.get() + 1));
}

fn allocations_on_this_thread() -> usize {
    ALLOCATIONS.with(Cell::get)
}

fn read(handle: &mut Handle, output: &mut [u8], error: &mut [u8]) -> i32 {
    let capacity_frames = READ_FRAMES.unsigned_abs();

    unsafe {
        symphonia_read(&raw mut *handle, output.as_mut_ptr(), capacity_frames, error.as_mut_ptr(), ERROR_CAPACITY)
    }
}

fn allocations_over_steady_reads(name: &str) -> usize {
    let mut handle = Handle::Direct(Session::from_reader(Box::new(Replay::demux(name)), None).unwrap());
    let mut output = vec![0_u8; READ_FRAMES.unsigned_abs() as usize * BYTES_PER_FRAME];
    let mut error = vec![0_u8; ERROR_CAPACITY as usize];

    assert_eq!(read(&mut handle, &mut output, &mut error), READ_FRAMES, "{name}: the warm-up read");

    let before = allocations_on_this_thread();

    for index in 0..STEADY_READS {
        assert_eq!(read(&mut handle, &mut output, &mut error), READ_FRAMES, "{name}: read {index}");
    }

    allocations_on_this_thread() - before
}

#[test]
fn steady_reads_of_demuxed_packets_allocate_nothing() {
    for name in FIXTURES_WITH_HEAP_FREE_DECODERS {
        assert_eq!(allocations_over_steady_reads(name), 0, "{name}");
    }
}
