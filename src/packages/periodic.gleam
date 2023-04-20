import gleam/otp/actor
import gleam/erlang/process.{Subject}

pub opaque type Message {
  Rerun
}

type State(a) {
  State(self: Subject(Message), work: fn() -> a, interval: Int)
}

/// Repeatedly call a function, leaving `interval` milliseconds between each
/// call.
/// Doesn't handle crashes at all.
pub fn periodically(
  do work: fn() -> whatever,
  waiting interval: Int,
) -> Result(Subject(Message), actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() { init(interval, work) },
    loop: loop,
    init_timeout: 100,
  ))
}

fn init(interval: Int, work: fn() -> a) -> actor.InitResult(State(a), Message) {
  let subject = process.new_subject()
  let state = State(subject, work, interval)
  let selector =
    process.new_selector()
    |> process.selecting(subject, fn(x) { x })

  enqueue_next_rerun(state)
  actor.Ready(state, selector)
}

fn loop(message: Message, state: State(a)) -> actor.Next(State(a)) {
  case message {
    Rerun -> {
      state.work()
      enqueue_next_rerun(state)
      actor.Continue(state)
    }
  }
}

fn enqueue_next_rerun(state: State(a)) -> Nil {
  process.send_after(state.self, state.interval, Rerun)
  Nil
}
