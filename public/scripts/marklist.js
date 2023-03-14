function addToMarklist(x) {
  var curr_marklist = getCookie('marklist');
  if (curr_marklist.search(x+'($|,)') == -1) {
    let sep = curr_marklist == '' ? '' : ',';
    setCookie('marklist', curr_marklist + sep + x);
    refreshMarklist();
  }
}

function refreshMarklist() {
  // Remove all values from marklist and redraw
  var ml = document.getElementById('marklist');
  ml.replaceChildren();
  var species = getCookie('marklist').split(',');
  species.forEach(function(x) {
    if (x == '') return;
    var li = document.createElement("li");
    li.setAttribute("class", "marklist-item");
    li.setAttribute("id", "ml-" + x);
    li.textContent = x;

    var remove_button = document.createElement("button");
    remove_button.setAttribute("type", "button");
    remove_button.setAttribute("class", "btn btn-danger btn-small");
    remove_button.setAttribute("onclick", "removeFromMarklist('"+x+"')");
    remove_button.textContent = '-';

    li.appendChild(remove_button);
    ml.appendChild(li);
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
}

function removeFromMarklist(x) {
  // Remove species from cookie then redraw marklist
  var curr_cookie = getCookie('marklist');
  re = new RegExp(x + '\\b,?')
  curr_cookie = curr_cookie.replace(re, "")
  curr_cookie = curr_cookie.replace(/,$/, "")  // If the target species was last there will be a trailing comma
  setCookie('marklist', curr_cookie);

  refreshMarklist();
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
