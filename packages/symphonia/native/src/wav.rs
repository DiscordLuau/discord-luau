use std::io::{self, Read, Seek, SeekFrom};

const IDENTIFIER_LENGTH: usize = 4;
const SIZE_LENGTH: usize = 4;
const FORM_TYPE_OFFSET: usize = IDENTIFIER_LENGTH + SIZE_LENGTH;
const RIFF_HEADER_LENGTH: usize = FORM_TYPE_OFFSET + IDENTIFIER_LENGTH;
const CHUNK_HEADER_LENGTH: usize = IDENTIFIER_LENGTH + SIZE_LENGTH;
const FACT_FRAMES_LENGTH: usize = size_of::<u32>();
const HEADER_LIMIT: u64 = 65_536;
const WAVE_CONTAINER_NAME: &str = "wave";
const PCM_CODEC_PREFIX: &str = "pcm_";

pub fn fact_frames(header: &[u8]) -> Option<u64> {
    if !header.starts_with(b"RIFF") || header.get(FORM_TYPE_OFFSET..RIFF_HEADER_LENGTH)? != b"WAVE" {
        return None;
    }

    let mut position = RIFF_HEADER_LENGTH;

    while let Some(chunk_header) = header.get(position..position.checked_add(CHUNK_HEADER_LENGTH)?) {
        let (identifier, size) = chunk_header.split_at(IDENTIFIER_LENGTH);
        let size = u32::from_le_bytes(size.try_into().ok()?) as usize;
        let body = position + CHUNK_HEADER_LENGTH;

        match identifier {
            b"fact" => {
                let frames = header.get(body..body.checked_add(FACT_FRAMES_LENGTH)?)?;

                return Some(u64::from(u32::from_le_bytes(frames.try_into().ok()?)));
            }
            b"data" => return None,
            // RIFF pads a chunk of odd size with one byte, so the next chunk starts on an even offset.
            _ => position = body.checked_add(size)?.checked_add(size & 1)?,
        }
    }

    None
}

pub fn read_fact_frames(source: &mut (impl Read + Seek)) -> io::Result<Option<u64>> {
    let mut header = Vec::new();

    source.by_ref().take(HEADER_LIMIT).read_to_end(&mut header)?;
    source.seek(SeekFrom::Start(0))?;

    Ok(fact_frames(&header))
}

pub fn playable_frames(
    stated_frames: Option<u64>,
    container_name: &str,
    codec_name: &str,
    fact_frames: Option<u64>,
) -> Option<u64> {
    let padded = container_name == WAVE_CONTAINER_NAME && !codec_name.starts_with(PCM_CODEC_PREFIX);

    match (stated_frames, fact_frames) {
        (Some(stated), Some(fact)) if padded && fact > 0 && fact < stated => Some(fact),
        _ => stated_frames,
    }
}
