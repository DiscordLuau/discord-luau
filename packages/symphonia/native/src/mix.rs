//! Any channel layout to stereo. Positioned layouts use a coefficient per position, scaled so full-scale input cannot
//! clip; Ambisonic audio uses its W component as mono; other layouts use their first one or two channels.

use symphonia::core::audio::{Channels, Position};

pub const OUTPUT_CHANNELS: usize = 2;

const MINUS_3_DB: f32 = std::f32::consts::FRAC_1_SQRT_2;
const OPPOSITE_CENTRE: f32 = 1.0 - MINUS_3_DB;
const REAR_CENTRE: f32 = 0.5;

#[derive(Debug, Clone, Copy, PartialEq)]
struct Contribution {
    plane: usize,
    coefficient: f32,
}

impl Contribution {
    fn new(plane: usize, coefficient: f32) -> Self {
        Self { plane, coefficient }
    }
}

/// How the planes of one decoded buffer sum into the left and right outputs.
#[derive(Debug, Clone, PartialEq)]
pub struct StereoMix {
    left: Vec<Contribution>,
    right: Vec<Contribution>,
}

impl StereoMix {
    /// One plane is always duplicated, and a positioned layout where no channel feeds a side (only LFE, say) falls
    /// back to the first planes.
    pub fn for_channels(channels: &Channels, plane_count: usize) -> Self {
        if plane_count == 1 {
            return Self::mono(0);
        }

        match channels {
            Channels::Positioned(positions) => Self::positioned(channels, *positions, plane_count),
            Channels::Ambisonic(_) if plane_count > 0 => Self::mono(0),
            _ => Self::first_planes(plane_count),
        }
    }

    /// Appends the first `frames` frames of `planes` to `output` as interleaved stereo; a mix of no planes appends
    /// silence, so the length is kept.
    pub fn apply(&self, planes: &[Vec<f32>], frames: usize, output: &mut Vec<f32>) {
        output.reserve(frames * OUTPUT_CHANNELS);

        for frame in 0..frames {
            output.push(Self::side(&self.left, planes, frame));
            output.push(Self::side(&self.right, planes, frame));
        }
    }

    fn mono(plane: usize) -> Self {
        let only = vec![Contribution::new(plane, 1.0)];

        Self { left: only.clone(), right: only }
    }

    fn first_two() -> Self {
        Self { left: vec![Contribution::new(0, 1.0)], right: vec![Contribution::new(1, 1.0)] }
    }

    fn first_planes(plane_count: usize) -> Self {
        match plane_count {
            0 => Self { left: Vec::new(), right: Vec::new() },
            1 => Self::mono(0),
            _ => Self::first_two(),
        }
    }

    fn positioned(channels: &Channels, positions: Position, plane_count: usize) -> Self {
        let mut left = Vec::new();
        let mut right = Vec::new();

        for bit in 0..u64::BITS {
            let position = Position::from_bits_retain(1 << bit);

            if !positions.contains(position) {
                continue;
            }

            let Some(plane) = channels.get_canonical_index_for_positioned_channel(position) else {
                continue;
            };

            if plane >= plane_count {
                continue;
            }

            let (left_coefficient, right_coefficient) = coefficients(position);

            if left_coefficient != 0.0 {
                left.push(Contribution::new(plane, left_coefficient));
            }

            if right_coefficient != 0.0 {
                right.push(Contribution::new(plane, right_coefficient));
            }
        }

        match (left.is_empty(), right.is_empty()) {
            (true, true) => return Self::first_planes(plane_count),
            (true, false) => left.clone_from(&right),
            (false, true) => right.clone_from(&left),
            (false, false) => {}
        }

        normalise(&mut left);
        normalise(&mut right);

        Self { left, right }
    }

    fn side(contributions: &[Contribution], planes: &[Vec<f32>], frame: usize) -> f32 {
        contributions.iter().map(|contribution| planes[contribution.plane][frame] * contribution.coefficient).sum()
    }
}

/// The `(left, right)` coefficients for one position. LFE channels, and positions Symphonia may add later, are
/// dropped.
fn coefficients(position: Position) -> (f32, f32) {
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

    if FRONT_LEFT.contains(position) {
        (1.0, 0.0)
    } else if FRONT_RIGHT.contains(position) {
        (0.0, 1.0)
    } else if CENTRE.contains(position) {
        (MINUS_3_DB, MINUS_3_DB)
    } else if position == Position::FRONT_LEFT_CENTER {
        (MINUS_3_DB, OPPOSITE_CENTRE)
    } else if position == Position::FRONT_RIGHT_CENTER {
        (OPPOSITE_CENTRE, MINUS_3_DB)
    } else if SURROUND_LEFT.contains(position) {
        (MINUS_3_DB, 0.0)
    } else if SURROUND_RIGHT.contains(position) {
        (0.0, MINUS_3_DB)
    } else if BACK_CENTRE.contains(position) {
        (REAR_CENTRE, REAR_CENTRE)
    } else {
        (0.0, 0.0)
    }
}

/// Divides each coefficient by the sum of the side's absolute coefficients.
fn normalise(side: &mut [Contribution]) {
    let total: f32 = side.iter().map(|contribution| contribution.coefficient.abs()).sum();

    for contribution in side.iter_mut() {
        contribution.coefficient /= total;
    }
}
