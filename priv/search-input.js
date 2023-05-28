"use strict";

document.addEventListener("keypress", (event) => {
  if (event.key === "s" || event.key === "S") {
    const searchInput = document.getElementById("search-input");
    if (searchInput) {
      const isAlreadyFocused = document.activeElement === searchInput;
      if (!isAlreadyFocused) {
        // Prevent the "S" from being added to the search when we focus it.
        event.preventDefault();

        searchInput.focus();
      }
    }
  }
});
