//! What a stream session and its worker share behind one lock: what the worker last published, the failure and the
//! stop flag. The session answers calls from it, so it never waits on a decode.

use crate::error::Error;
use crate::fields::{DescribeField, InfoField, State, UNKNOWN};
use crate::session::Session;

const INFO_WHILE_PROBING: [i32; InfoField::ALL.len()] = [UNKNOWN, UNKNOWN, UNKNOWN, UNKNOWN, 0, 0, 0, 0];

pub struct Status {
    state: State,
    failure: Option<Error>,
    info: [i32; InfoField::ALL.len()],
    codec_name: String,
    container_name: String,
    stopped: bool,
}

impl Status {
    pub fn new() -> Self {
        Self {
            state: State::Probing,
            failure: None,
            info: INFO_WHILE_PROBING,
            codec_name: String::new(),
            container_name: String::new(),
            stopped: false,
        }
    }

    pub fn publish(&mut self, session: &Session, state: State) {
        if self.state == State::Probing {
            self.codec_name = session.describe(DescribeField::Codec);
            self.container_name = session.describe(DescribeField::Container);
        }

        for field in InfoField::ALL {
            self.info[field as usize] = session.info(field);
        }

        self.state = state;
    }

    pub fn state(&self) -> State {
        if self.failure.is_some() { State::Failed } else { self.state }
    }

    pub fn info(&self, field: InfoField) -> i32 {
        match field {
            InfoField::IsFailed => i32::from(self.state() == State::Failed),
            InfoField::State => self.state() as i32,
            published => self.info[published as usize],
        }
    }

    pub fn describe(&self, field: DescribeField) -> String {
        match field {
            DescribeField::Codec => self.codec_name.clone(),
            DescribeField::Container => self.container_name.clone(),
            DescribeField::Failure => self.failure.as_ref().map(Error::to_string).unwrap_or_default(),
        }
    }

    pub fn failure(&self) -> Option<&Error> {
        self.failure.as_ref()
    }

    pub fn mark_failed(&mut self, error: Error) {
        self.failure.get_or_insert(error);
    }

    pub fn stop(&mut self) {
        self.stopped = true;
    }

    pub fn is_stopped(&self) -> bool {
        self.stopped
    }
}
