function showPage(i, N) {
    hideAllPages(N);
    let ele = document.getElementById("page-" + i);
    ele.hidden = false;
    let button = document.getElementById("list-button-" + i);
    button.classList.add("active");
}

function hideAllPages(N) {
    for (let i = 1; i <= N; i++) {
        let reaction_list = document.getElementById("page-" + i);
        reaction_list.hidden = true;
        let button = document.getElementById("list-button-" + i);
        button.classList.remove("active");
    }
}
