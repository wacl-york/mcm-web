function redirectMechanism(new_mechanism) {
    // Redirects the current page to a mechanism specified via a Select input
    //
    // Assumes that the current page is /old_mechanism/some/page and redirects to
    // /new_mechanism/some/page, where new_mechanism is the chosen item from a Select input.
    // 
    // Args:
    //   - new_mechanism (String): Name of the mechanism to navigate to.
    //
    // Returns:
    //   - None. Redirects page instead.
    var curr_path = window.location.pathname;

    // Have to assume that the first route of the current page is the mechanism
    var new_path = curr_path.replace(/^\/[A-Z0-9a-z]+\/?/, "/" + new_mechanism + "/");

    // Clear marklist to avoid any conflicts of species that aren't available in multiple mechanisms
    clearMarklist();

    window.location = new_path;
}
