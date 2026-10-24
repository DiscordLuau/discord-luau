//! The chosen track's packets, taken from the container, and the run of packets passed over on the way.

use std::io::ErrorKind;

use symphonia::core::errors::Error as SymphoniaError;
use symphonia::core::formats::FormatReader;
use symphonia::core::packet::Packet;

use crate::error::Error;
use crate::limits::MAX_CONSECUTIVE_SKIPS;

pub(crate) struct Demuxer {
    reader: Box<dyn FormatReader>,
    track_id: u32,
    skipped_packets: u64,
    /// Skipped packets of the chosen track and packets of other tracks, since the last packet used.
    consecutive_skips: u64,
    pending: Option<Packet>,
    ended: bool,
}

impl Demuxer {
    pub(crate) fn new(reader: Box<dyn FormatReader>, track_id: u32) -> Self {
        Self { reader, track_id, skipped_packets: 0, consecutive_skips: 0, pending: None, ended: false }
    }

    pub(crate) fn skipped_packets(&self) -> u64 {
        self.skipped_packets
    }

    pub(crate) fn next_packet(&mut self) -> Result<Option<Packet>, Error> {
        if let Some(packet) = self.pending.take() {
            return Ok(Some(packet));
        }

        if self.ended {
            return Ok(None);
        }

        loop {
            match self.reader.next_packet() {
                Ok(Some(packet)) if packet.track_id == self.track_id => return Ok(Some(packet)),
                Ok(Some(_)) => self.extend_run()?,
                Ok(None) => {
                    self.ended = true;
                    return Ok(None);
                }
                // Symphonia's own idiom for the end of the bytes. Whether that was early is decided against the stated
                // length when decoding finishes.
                Err(failure) if is_unexpected_end(&failure) => {
                    self.ended = true;
                    return Ok(None);
                }
                Err(SymphoniaError::ResetRequired) => return Err(Error::StreamChanged),
                Err(failure) => return Err(Error::UnreadableContainer(failure.to_string())),
            }
        }
    }

    pub(crate) fn put_back(&mut self, packet: Packet) {
        self.pending = Some(packet);
    }

    /// Counts a skipped packet of the chosen track, which also extends the run.
    pub(crate) fn skip(&mut self) -> Result<(), Error> {
        self.skipped_packets += 1;
        self.extend_run()
    }

    pub(crate) fn reset_skips(&mut self) {
        self.consecutive_skips = 0;
    }

    fn extend_run(&mut self) -> Result<(), Error> {
        self.consecutive_skips += 1;

        if self.consecutive_skips > MAX_CONSECUTIVE_SKIPS {
            return Err(Error::TooManySkips);
        }

        Ok(())
    }
}

/// Symphonia's idiom for bytes that ran out partway through a read.
pub(crate) fn is_unexpected_end(error: &SymphoniaError) -> bool {
    matches!(error, SymphoniaError::IoError(failure) if failure.kind() == ErrorKind::UnexpectedEof)
}
