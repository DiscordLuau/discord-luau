use crate::error::Error;

const MAGIC: &[u8; 8] = b"OpusHead";
const MAPPING_FAMILY_OFFSET: usize = 18;
const STREAM_COUNT_OFFSET: usize = MAPPING_FAMILY_OFFSET + 1;
const COUPLED_COUNT_OFFSET: usize = STREAM_COUNT_OFFSET + 1;
pub const FAMILY_HEADER_LENGTH: usize = MAPPING_FAMILY_OFFSET + 1;
pub(crate) const MAPPING_HEADER_LENGTH: usize = COUPLED_COUNT_OFFSET + 1;
const MAX_CHANNELS_WITHOUT_HEAD: usize = 2;
const MONO_OR_STEREO_FAMILY: u8 = 0;
const VORBIS_FAMILY: u8 = 1;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct OpusHead {
    pub(crate) mapping_family: u8,
    pub(crate) stream_count: u8,
}

impl OpusHead {
    pub(crate) fn parse(bytes: &[u8]) -> Result<Option<Self>, Error> {
        if !bytes.starts_with(MAGIC) {
            return Ok(None);
        }

        let Some(&mapping_family) = bytes.get(MAPPING_FAMILY_OFFSET) else {
            return Err(Error::ShortOpusHead(bytes.len()));
        };

        if mapping_family == MONO_OR_STEREO_FAMILY {
            return Ok(Some(Self { mapping_family, stream_count: 1 }));
        }

        if bytes.len() < MAPPING_HEADER_LENGTH {
            return Err(Error::ShortMappingTable { mapping_family, length: bytes.len() });
        }

        Ok(Some(Self { mapping_family, stream_count: bytes[STREAM_COUNT_OFFSET] }))
    }
}

pub fn check_passthrough(extra_data: Option<&[u8]>, channel_count: Option<usize>) -> Result<(), Error> {
    let head = match extra_data {
        Some(bytes) => OpusHead::parse(bytes)?,
        None => None,
    };

    match head {
        Some(
            OpusHead { mapping_family: MONO_OR_STEREO_FAMILY, .. }
            | OpusHead { mapping_family: VORBIS_FAMILY, stream_count: 1 },
        ) => Ok(()),
        Some(_) => Err(Error::MultistreamOpus),
        None => match channel_count {
            Some(count) if count <= MAX_CHANNELS_WITHOUT_HEAD => Ok(()),
            Some(_) => Err(Error::MultistreamOpus),
            None => Err(Error::UnknownOpusChannels),
        },
    }
}
