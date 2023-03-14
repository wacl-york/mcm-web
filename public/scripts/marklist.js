function addToMarklist(x) {
  var curr_marklist = getCookie('marklist');
  if (curr_marklist.search(x+'($|,)') == -1) {
    let sep = curr_marklist == '' ? '' : ',';
    setCookie('marklist', curr_marklist + sep + x);
    refreshMarklist();
  }
}

function refreshMarklist() {
  var ml = document.getElementById('marklist');
  species = getCookie('marklist').split(',');
  species.forEach(function(x) {
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

function checkCookie() {
  let user = getCookie("username");
  if (user != "") {
    alert("Welcome again " + user);
  } else {
    user = prompt("Please enter your name:", "");
    if (user != "" && user != null) {
      setCookie("username", user, 365);
    }
  }
}

function clearMarklist() {
  setCookie('marklist', '');
  var ml = document.getElementById('marklist');
  ml.replaceChildren();
}

function removeFromMarklist(x) {
  // Remove species from cookie
  var curr_cookie = getCookie('marklist');
  re = new RegExp(x + '\\b,?')
  curr_cookie = curr_cookie.replace(re, "")
  curr_cookie = curr_cookie.replace(/,$/, "")  // If the target species was last there will be a trailing comma
  setCookie('marklist', curr_cookie);

  // Remove species from marklist
  var ele = document.getElementById('ml-' + x);
  ele.remove();
}
