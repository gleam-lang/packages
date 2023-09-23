import packages/error.{Error}
import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/io

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
) -> Result(Subject(Message), actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() { init(interval, work) },
    loop: loop,
    init_timeout: 100,
  ))
}

fn init(
  interval: Int,
  work: fn() -> Result(a, Error),
) -> actor.InitResult(State(a), Message) {
  let subject = process.new_subject()
  let state = State(subject, work, interval)
  let selector =
    process.new_selector()
    |> process.selecting(subject, fn(x) { x })

  enqueue_next_rerun(state)
  actor.Ready(state, selector)
}

fn loop(message: Message, state: State(a)) -> actor.Next(Message, State(a)) {
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
      io.debug(e)
      Nil
    }
  }
}
