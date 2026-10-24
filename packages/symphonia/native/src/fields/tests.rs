//! The field numbers, which `sys.luau` repeats.

use super::*;

#[test]
fn every_field_is_found_by_its_own_number() {
    for (index, field) in InfoField::ALL.into_iter().enumerate() {
        assert_eq!(field as usize, index, "{field:?} is at its number in ALL");
        assert_eq!(InfoField::from_number(field as i32), Some(field));
    }

    for (index, field) in DescribeField::ALL.into_iter().enumerate() {
        assert_eq!(field as usize, index, "{field:?} is at its number in ALL");
        assert_eq!(DescribeField::from_number(field as i32), Some(field));
    }

    assert_eq!(InfoField::from_number(-1), None);
    assert_eq!(InfoField::from_number(8), None);
    assert_eq!(DescribeField::from_number(-1), None);
    assert_eq!(DescribeField::from_number(3), None);
}

#[test]
fn the_numbers_are_the_ones_sys_luau_uses() {
    assert_eq!(InfoField::ALL.map(|field| field as i32), [0, 1, 2, 3, 4, 5, 6, 7]);
    assert_eq!(InfoField::State as i32, 7);
    assert_eq!(InfoField::EndedEarly as i32, 6);
    assert_eq!(DescribeField::Failure as i32, 2);
    assert_eq!([State::Probing, State::Open, State::Ended, State::Failed].map(|state| state as i32), [0, 1, 2, 3]);
}
