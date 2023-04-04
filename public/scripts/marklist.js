window.onload = updateMarklistIconCount;

function addToMarklist(x) {
  var curr_marklist = getCookie('marklist');
  if (curr_marklist.search(x+'($|,)') == -1) {
    let sep = curr_marklist == '' ? '' : ',';
    setCookie('marklist', curr_marklist + sep + x);
    refreshMarklist();
  }
  updateMarklistIconCount();

  // If marklist was previously empty, display it
  if (getMarklistLengthFromCookie() > 0 && !marklistIsVisible()) {
    showMarklist();
    enableExportButton();
  }
}

function getMarklistLengthFromCookie() {
  var curr_marklist = getCookie('marklist');
  var n_items = 0;
  if (curr_marklist != '') {
      n_items = curr_marklist.split(",").length
  }
  return n_items;
}

function updateMarklistIconCount() {
  var icon = document.getElementById('marklist-count');
  icon.textContent = getMarklistLengthFromCookie();
}

function refreshMarklist() {
  // Remove all values from marklist and redraw
  var ml = document.getElementById('marklist');
  ml.replaceChildren();
  var species = getCookie('marklist').split(',');
  species.forEach(function(x) {
    // Each species is represented by:
    // 1. a containing div (needed to apply styles that can't apply to li)
    // 2. an li
    // 3. a button (to remove from marklist)

    if (x == '') return;
    var div = document.createElement("div");
    div.setAttribute("class", "marklist-item");
    div.setAttribute("id", "ml-" + x);

    var remove_button = document.createElement("button");
    remove_button.setAttribute("type", "button");
    remove_button.setAttribute("class", "btn btn-danger btn-small btn-marklist");
    remove_button.setAttribute("onclick", "removeFromMarklist('"+x+"')");
    remove_button.textContent = '-';

    var species_label = document.createElement("span");
    species_label.textContent = x;

    div.appendChild(remove_button);
    div.appendChild(species_label);
    ml.appendChild(div);
  });
}

function setCookie(cname, cvalue) {
  let expires="Session";
  document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/;SameSite=Strict;";
}

function getCookie(cname) {
  let name = cname + "=";
  let ca = document.cookie.split(';');
  for(let i = 0; i < ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) == ' ') {
      c = c.substring(1);
    }
    if (c.indexOf(name) == 0) {
      return c.substring(name.length, c.length);
    }
  }
  return "";
}

function clearMarklist() {
  setCookie('marklist', '');
  refreshMarklist();
  updateMarklistIconCount();
  disableExportButton();
}

function removeFromMarklist(x) {
  // Remove species from cookie then redraw marklist
  var curr_cookie = getCookie('marklist');
  re = new RegExp(x + '\\b,?')
  curr_cookie = curr_cookie.replace(re, "")
  curr_cookie = curr_cookie.replace(/,$/, "")  // If the target species was last there will be a trailing comma
  setCookie('marklist', curr_cookie);

  refreshMarklist();
  updateMarklistIconCount();
  if (getMarklistLengthFromCookie() == 0) {
      disableExportButton();
  }
}

function enableExportButton() {
    const btn = document.getElementById('exportMarklistButton');
    btn.classList.remove("disabled");
}

function disableExportButton() {
    const btn = document.getElementById('exportMarklistButton');
    btn.classList.add("disabled");
}

function showMarklist() {
    const ml = new bootstrap.Offcanvas('#marklistCanvas')
    ml.show();
}

function marklistIsVisible() {
    const ml = document.getElementById('marklistCanvas');
    ml.classList.contains("show");
}

function populateExportMarklist() {
  // Remove all values from marklist and redraw
  var ml = document.getElementById('export-marklist');
  ml.replaceChildren();
  var species = getCookie('marklist').split(',');
  species.forEach(function(x) {
    if (x == '') return;

    var input = document.createElement("input");
    input.setAttribute("type", "checkbox");
    input.setAttribute("name", "selected[]");
    input.setAttribute("id", "export-"+x);
    input.setAttribute("value", x);
    input.setAttribute("checked", true);

    var label = document.createElement("label");
    label.setAttribute("for", "export-"+x);
    label.textContent = x;

    ml.appendChild(input);
    ml.appendChild(label);
  });
}
