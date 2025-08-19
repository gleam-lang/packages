import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/string
import packages/error.{type Error}
import wisp

pub opaque type Message {
  Rerun
}

type State(a) {
  State(self: Subject(Message), work: fn() -> Result(a, Error), interval: Int)
}

/// Repeatedly call a function, leaving `interval` milliseconds between each
/// call.
/// When the `work` function returns an error it is printed.
pub fn periodically(
  do work: fn() -> Result(a, Error),
  waiting interval: Int,
) -> Result(actor.Started(Subject(Message)), actor.StartError) {
  actor.new_with_initialiser(100, init(interval, work, _))
  |> actor.on_message(loop)
  |> actor.start
}

fn init(
  interval: Int,
  work: fn() -> Result(a, Error),
  self,
) -> Result(actor.Initialised(State(a), Message, Subject(Message)), b) {
  let state = State(self, work, interval)

  let selector =
    process.new_selector()
    |> process.select(self)

  enqueue_next_rerun(state)

  actor.initialised(state)
  |> actor.selecting(selector)
  |> actor.returning(self)
  |> Ok
}

fn loop(state: State(a), message: Message) -> actor.Next(State(a), b) {
  case message {
    Rerun -> {
      log_error(state.work())
      enqueue_next_rerun(state)
      actor.continue(state)
    }
  }
}

fn enqueue_next_rerun(state: State(a)) -> Nil {
  process.send_after(state.self, state.interval, Rerun)
  Nil
}

fn log_error(result: Result(a, b)) -> Nil {
  case result {
    Ok(_) -> Nil
    Error(e) -> {
      wisp.log_error(string.inspect(e))
      Nil
    }
  }
}
