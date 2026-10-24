//! What a stream session and its worker share behind one lock: what the worker last published, the failure and the
//! stop flag. The session answers calls from it, so it never waits on a decode.

use crate::error::Error;
use crate::fields::{DescribeField, State};
use crate::session::{Info, Session};

pub(crate) struct Status {
    state: State,
    failure: Option<Error>,
    info: Option<Info>,
    codec_name: String,
    container_name: String,
    stopped: bool,
}

impl Status {
    pub(crate) fn new() -> Self {
        Self {
            state: State::Probing,
            failure: None,
            info: None,
            codec_name: String::new(),
            container_name: String::new(),
            stopped: false,
        }
    }

    pub(crate) fn publish(&mut self, session: &Session, state: State) {
        if self.state == State::Probing {
            self.codec_name = session.describe(DescribeField::Codec);
            self.container_name = session.describe(DescribeField::Container);
        }

        self.info = Some(session.info());
        self.state = state;
    }

    pub(crate) fn state(&self) -> State {
        if self.failure.is_some() { State::Failed } else { self.state }
    }

    pub(crate) fn info(&self) -> Option<Info> {
        self.info
    }

    pub(crate) fn describe(&self, field: DescribeField) -> String {
        match field {
            DescribeField::Codec => self.codec_name.clone(),
            DescribeField::Container => self.container_name.clone(),
            DescribeField::Failure => self.failure.as_ref().map(Error::to_string).unwrap_or_default(),
        }
    }

    pub(crate) fn failure(&self) -> Option<&Error> {
        self.failure.as_ref()
    }

    pub(crate) fn mark_failed(&mut self, error: Error) {
        self.failure.get_or_insert(error);
    }

    pub(crate) fn stop(&mut self) {
        self.stopped = true;
    }

    pub(crate) fn is_stopped(&self) -> bool {
        self.stopped
    }
}
