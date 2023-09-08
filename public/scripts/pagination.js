function createNavEntry(pageNumber, label, currentPage, maxPage) {
    let li = document.createElement('li');
    li.setAttribute('class', 'page-item');
    if (pageNumber == currentPage) {
        li.classList.add('active');
    }
    li.setAttribute('id', 'list-button-' + pageNumber);
    let button = document.createElement("button");
    button.setAttribute("class", "page-link");
    button.setAttribute("type", "button");
    button.onclick = function() {showPage(pageNumber, maxPage)};
    button.textContent = label;
    li.appendChild(button);
    return li;
}

function populateNav(currentPage, maxPage, delta) {
    var startPage = 1;
    var endPage = maxPage;

    // Logic adapted from StackOverflow
    // https://stackoverflow.com/a/31836340
    if (maxPage <= (2*delta) + 5) {
        // in this case, too few pages, so display them all
        startPage = 1
        endPage = maxPage
    } else if (currentPage <= delta + 3) {
        // in this case, currentPage is too close to the beginning
        startPage = 1
        endPage = (2*delta)+3
    } else if (currentPage >= maxPage - (delta+2)) {
        // in this case, currentPage is too close to the end
        startPage = maxPage - (2*delta) - 2
        endPage = maxPage
    } else {
        // regular case
        startPage = currentPage - delta
        endPage = currentPage + delta
    }

    let container = document.getElementById('precursor-pagination-nav');
    container.replaceChildren();

    if (startPage > 1)
        container.appendChild(createNavEntry(1, '1', currentPage, maxPage));
    if (startPage > 2)
        container.appendChild(createNavEntry(startPage-1, '...', currentPage, maxPage));
    for (let i=startPage; i <= endPage; i++) {
        container.appendChild(createNavEntry(i, i, currentPage, maxPage));
    }
    if (endPage < maxPage - 1)
        container.appendChild(createNavEntry(endPage+1, '...', currentPage, maxPage));
    if (endPage < maxPage)
        container.appendChild(createNavEntry(maxPage, maxPage, currentPage, maxPage));
}

function showPage(i, N) {
    // Display the paged reactions
    // TODO Only hide last page if can keep track of state
    hideAllPages(N);
    let ele = document.getElementById("page-" + i);
    ele.hidden = false;

    // Keep state of currently viewed page for toggling display of all the reactions
    // i.e. so can hide all reactions, then when toggle again will revert back to the previously
    // opened page rather than defaulting to first
    current_precursor_reaction_page = i;

    // Update the navigation buttons list
    populateNav(i, N, 2);
}

function hideAllPages(N) {
    for (let i = 1; i <= N; i++) {
        let reaction_list = document.getElementById("page-" + i);
        reaction_list.hidden = true;
    }
}

function togglePrecursorReactions(but, max_page) {
    let container = document.getElementById("precursorRxnsCollapse");
    // Toggle container visibility
    container.hidden = !container.hidden;

    // Show the current page
    if (!container.hidden) {
        showPage(current_precursor_reaction_page, max_page);
    }

    // Update button text to reflect status
    but.textContent = container.hidden ? 'Show precursor reactions' : 'Hide precursor reactions';
}
