document.addEventListener("keypress", (event) => {
  if (event.key === "/") {
    const searchInput = document.querySelector("[data-search-input]");
    if (searchInput) {
      const isAlreadyFocused = document.activeElement === searchInput;
      if (!isAlreadyFocused) {
        // Prevent the "/" from being added to the search when we focus it.
        event.preventDefault();

        searchInput.focus();
      }
    }
  }
});
