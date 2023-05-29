const keybinds = {};

function focus(element, event) {
  if (document.activeElement !== element) {
    event.preventDefault();
    element.focus();
  }
}

for (const element of document.querySelectorAll("[data-keybind-focus]")) {
  keybinds[element.dataset.keybindFocus] = (event) => focus(element, event);
}

document.addEventListener("keypress", (event) => {
  keybinds[event.key.toLowerCase()]?.(event);
});
