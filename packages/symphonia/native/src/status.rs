use std::borrow::Cow;

use crate::error::Error;
use crate::fields::{DescribeField, State};
use crate::session::{Info, Session};

pub(crate) struct Status {
    state: State,
    failure: Option<Error>,
    info: Option<Info>,
    codec_name: &'static str,
    container_name: &'static str,
    stopped: bool,
}

impl Status {
    pub(crate) fn new() -> Self {
        Self { state: State::Probing, failure: None, info: None, codec_name: "", container_name: "", stopped: false }
    }

    pub(crate) fn publish(&mut self, session: &Session, state: State) {
        if self.state == State::Probing {
            self.codec_name = session.codec_name;
            self.container_name = session.container_name;
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

    pub(crate) fn describe(&self, field: DescribeField) -> Cow<'static, str> {
        match field {
            DescribeField::Codec => Cow::Borrowed(self.codec_name),
            DescribeField::Container => Cow::Borrowed(self.container_name),
            DescribeField::Failure => self.failure.as_ref().map_or(Cow::Borrowed(""), |error| error.to_string().into()),
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
