function addSpeciesToCookie(x) {
  var curr_marklist = getCookie('marklist');
  // Checking to see if species is in the cookie already
  if (curr_marklist.search('(^|,)'+x+'($|,)') == -1) {
    let sep = curr_marklist == '' ? '' : ',';
    setCookie('marklist', curr_marklist + sep + x);
  }
}

function updateMarklistButtonOnceAdded(species) {
  var button = document.getElementById("ml-add-" + species);
  if (button != null) {
      button.classList.remove("btn-success");
      button.classList.add("btn-danger");

      let current_text = button.innerHTML.trim();
      let new_text = '-';
      if (current_text == '+') {
          new_text = '-';
      } else if (current_text == 'Add to marklist') {
          new_text = "Remove from marklist";
      }
      button.innerHTML = new_text;
      button.setAttribute("onclick", "removeFromMarklist('"+species+"')");
  }
}

function updateMarklistButtonOnceRemoved(species) {
  var button = document.getElementById("ml-add-" + species);
  if (button != null) {
      button.classList.remove("btn-danger");
      button.classList.add("btn-success");

      let current_text = button.innerHTML.trim();
      let new_text = '+';
      if (current_text == '-') {
          new_text = '+';
      } else if (current_text == 'Remove from marklist') {
          new_text = "Add to marklist";
      }
      button.innerHTML = new_text;

      button.setAttribute("onclick", "addToMarklist('"+species+"')");
  }
}

function addToMarklist(x) {
  addSpeciesToCookie(x);
  updateMarklistButtonOnceAdded(x);
  refreshMarklist();
}

function addAllVOCsToMarklist() {
  // Get all VOCs from their links on this page. The MCM name is only obtainable from their URL
  // As the displayed text is their human readable name
  let eles = document.querySelectorAll("#browseTabContent div div div a");
  // This could be achieved with calling addToMarklist inside the loop
  // But that will lead to multiple redundant calls to refreshMarklist()
  eles.forEach(function(x) {
      let voc = x.getAttribute("href").replace(/\/.+\/species\//, "")
      addSpeciesToCookie(voc);
      updateMarklistButtonOnceAdded(voc);
  });
  refreshMarklist();
}

function addCurrentVOCGroupToMarklist() {
  // Find all species from the active tab item
  let eles = document.querySelectorAll("div.active .species-list .marklist-item a");
  // This could be achieved with calling addToMarklist inside the loop
  // But that will lead to multiple redundant calls to refreshMarklist()
  eles.forEach(function(x) {
      let voc = x.getAttribute("href").replace(/\/.+\/species\//, "")
      addSpeciesToCookie(voc);
      updateMarklistButtonOnceAdded(voc);
  });
  refreshMarklist();
}

async function getMarklistLengthFromCookie() {
  const species = await parseSpeciesFromCookie()
  return species.length
}

function updateMarklistIconCount() {
  const icon = document.getElementById('marklist-count');
  getMarklistLengthFromCookie().then( (length) => {
      icon.textContent = length;
  });
}

function refreshMarklist() {
  // Remove all values from marklist and redraw
  var ml = document.getElementById('marklist');
  ml.replaceChildren();
  parseSpeciesFromCookie().then( (species) => {
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
        remove_button.setAttribute("class", "btn btn-danger btn-small btn-marklist btn-marklist-sm");
        remove_button.setAttribute("onclick", "removeFromMarklist('"+x+"')");
        remove_button.textContent = '-';

        var species_label = document.createElement("span");
        species_label.textContent = x;

        div.appendChild(remove_button);
        div.appendChild(species_label);
        ml.appendChild(div);
      });
  });

  updateMarklistIconCount();

  getMarklistLengthFromCookie().then( (length) => {
      if (length == 0) {
          disableExportButton();
      } else if (length > 0) {
        enableExportButton();
      }
  });

  if (/\/export$/.test(window.location.pathname)) {
      populateExportMarklist();
  }
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
  // This could be done through multiple calls to
  // removeFromMarklist but that would have unnecessary
  // refreshes at each iteration
  parseSpeciesFromCookie().then( (species) => {
      species.forEach(function(x) {
        updateMarklistButtonOnceRemoved(x);
      });

      // Remove all species from the marklist by explicitly clearing cookie
      setCookie('marklist', '');
      refreshMarklist();
  });
}

function removeFromMarklist(x) {
  // Remove species from cookie then redraw marklist
  var curr_cookie = getCookie('marklist');
  re = new RegExp(x + '\\b,?')
  curr_cookie = curr_cookie.replace(re, "")
  curr_cookie = curr_cookie.replace(/,$/, "")  // If the target species was last there will be a trailing comma
  setCookie('marklist', curr_cookie);
  updateMarklistButtonOnceRemoved(x);

  refreshMarklist();
}

function enableExportButton() {
    const btn = document.getElementById('exportMarklistButton');
    btn.classList.remove("disabled");
}

function disableExportButton() {
    const btn = document.getElementById('exportMarklistButton');
    btn.classList.add("disabled");
}

async function parseSpeciesFromCookie() {
  // Parses the marklist cookie to extract valid species
  //
  // Args:
  //   None.
  //
  // Returns:
  //   An array of valid species names (as strings).
  const response = await fetch('/marklist-validate')
  const results = await response.json()
  return results['valid']
}

function populateExportMarklist() {
  parseSpeciesFromCookie().then( (species) => {
      // Remove all values from marklist and redraw
      var ml = document.getElementById('exportMarklist');
      ml.replaceChildren();

      species.forEach(function(x) {
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
  });
}
