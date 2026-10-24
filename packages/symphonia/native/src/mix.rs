//! Any channel layout to stereo. Positioned layouts use a coefficient per position, scaled so full-scale input cannot
//! clip; Ambisonic audio uses its W component as mono; other layouts use their first one or two channels.

use symphonia::core::audio::{Channels, Position};

use crate::limits::MAX_CHANNELS;

pub const OUTPUT_CHANNELS: usize = 2;

const LEFT: usize = 0;
const RIGHT: usize = 1;
const MINUS_3_DB: f32 = std::f32::consts::FRAC_1_SQRT_2;
const OPPOSITE_CENTRE: f32 = 1.0 - MINUS_3_DB;
const REAR_CENTRE: f32 = 0.5;

/// How the planes of one decoded buffer sum into the left and right outputs.
#[derive(Debug, Clone, Copy, Default, PartialEq)]
pub struct StereoMix {
    gains: [[f32; OUTPUT_CHANNELS]; MAX_CHANNELS],
}

impl StereoMix {
    /// One plane is always duplicated, and a positioned layout where no channel feeds a side (only LFE, say) falls
    /// back to the first planes.
    pub fn for_channels(channels: &Channels, plane_count: usize) -> Self {
        if plane_count == 1 {
            return Self::mono(0);
        }

        match channels {
            Channels::Positioned(positions) => Self::positioned(*positions, plane_count),
            Channels::Ambisonic(_) if plane_count > 0 => Self::mono(0),
            _ => Self::first_planes(plane_count),
        }
    }

    /// Appends the first `frames` frames of `planes` to `output` as interleaved stereo; a mix of no planes appends
    /// silence, so the length is kept.
    pub fn apply(&self, planes: &[Vec<f32>], frames: usize, output: &mut Vec<f32>) {
        let start = output.len();

        output.resize(start + frames * OUTPUT_CHANNELS, -0.0);

        let (stereo, _) = output[start..].as_chunks_mut::<OUTPUT_CHANNELS>();

        for (plane, gain) in planes.iter().zip(self.gains) {
            add_plane(stereo, plane, gain);
        }
    }

    fn mono(plane: usize) -> Self {
        let mut mix = Self::default();

        mix.gains[plane] = [1.0, 1.0];
        mix
    }

    fn first_two() -> Self {
        let mut mix = Self::default();

        mix.gains[0] = [1.0, 0.0];
        mix.gains[1] = [0.0, 1.0];
        mix
    }

    fn first_planes(plane_count: usize) -> Self {
        match plane_count {
            0 => Self::default(),
            1 => Self::mono(0),
            _ => Self::first_two(),
        }
    }

    fn positioned(positions: Position, plane_count: usize) -> Self {
        let mut mix = Self::default();

        for (gain, position) in mix.gains.iter_mut().zip(positions.iter()).take(plane_count) {
            *gain = coefficients(position);
        }

        match (mix.is_silent(LEFT), mix.is_silent(RIGHT)) {
            (true, true) => return Self::first_planes(plane_count),
            (true, false) => mix.copy_side(RIGHT, LEFT),
            (false, true) => mix.copy_side(LEFT, RIGHT),
            (false, false) => {}
        }

        mix.normalise(LEFT);
        mix.normalise(RIGHT);
        mix
    }

    fn is_silent(&self, side: usize) -> bool {
        self.gains.iter().all(|gain| gain[side] == 0.0)
    }

    fn copy_side(&mut self, source: usize, target: usize) {
        for gain in &mut self.gains {
            gain[target] = gain[source];
        }
    }

    /// Divides each gain by the sum of the side's absolute gains.
    fn normalise(&mut self, side: usize) {
        let total: f32 = self.gains.iter().filter(|gain| gain[side] != 0.0).map(|gain| gain[side].abs()).sum();

        for gain in &mut self.gains {
            gain[side] /= total;
        }
    }
}

fn add_plane(stereo: &mut [[f32; OUTPUT_CHANNELS]], plane: &[f32], [left_gain, right_gain]: [f32; OUTPUT_CHANNELS]) {
    for ([left, right], sample) in stereo.iter_mut().zip(plane) {
        if left_gain != 0.0 {
            *left += sample * left_gain;
        }

        if right_gain != 0.0 {
            *right += sample * right_gain;
        }
    }
}

/// The `[left, right]` coefficients for one position; LFE channels and positions Symphonia may add later are dropped.
fn coefficients(position: Position) -> [f32; OUTPUT_CHANNELS] {
    const FRONT_LEFT: Position = Position::FRONT_LEFT
        .union(Position::TOP_FRONT_LEFT)
        .union(Position::BOTTOM_FRONT_LEFT)
        .union(Position::FRONT_LEFT_WIDE);
    const FRONT_RIGHT: Position = Position::FRONT_RIGHT
        .union(Position::TOP_FRONT_RIGHT)
        .union(Position::BOTTOM_FRONT_RIGHT)
        .union(Position::FRONT_RIGHT_WIDE);
    const CENTRE: Position = Position::FRONT_CENTER
        .union(Position::TOP_CENTER)
        .union(Position::TOP_FRONT_CENTER)
        .union(Position::BOTTOM_FRONT_CENTER);
    const SURROUND_LEFT: Position =
        Position::SIDE_LEFT.union(Position::REAR_LEFT).union(Position::TOP_SIDE_LEFT).union(Position::TOP_REAR_LEFT);
    const SURROUND_RIGHT: Position = Position::SIDE_RIGHT
        .union(Position::REAR_RIGHT)
        .union(Position::TOP_SIDE_RIGHT)
        .union(Position::TOP_REAR_RIGHT);
    const BACK_CENTRE: Position = Position::REAR_CENTER.union(Position::TOP_REAR_CENTER);

    match position {
        _ if FRONT_LEFT.contains(position) => [1.0, 0.0],
        _ if FRONT_RIGHT.contains(position) => [0.0, 1.0],
        _ if CENTRE.contains(position) => [MINUS_3_DB, MINUS_3_DB],
        Position::FRONT_LEFT_CENTER => [MINUS_3_DB, OPPOSITE_CENTRE],
        Position::FRONT_RIGHT_CENTER => [OPPOSITE_CENTRE, MINUS_3_DB],
        _ if SURROUND_LEFT.contains(position) => [MINUS_3_DB, 0.0],
        _ if SURROUND_RIGHT.contains(position) => [0.0, MINUS_3_DB],
        _ if BACK_CENTRE.contains(position) => [REAR_CENTRE, REAR_CENTRE],
        _ => [0.0, 0.0],
    }
}
