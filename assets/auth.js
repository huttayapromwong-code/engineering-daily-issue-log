// Engineering Daily Issue Log — session guard for internal (non-public) pages.
// Include after config.js on any page that requires a signed-in user.
// Redirects to login.html if there's no session; injects a profile/logout
// control into .ds-topbar__actions once signed in.
(function () {
  "use strict";
  var SUPABASE_URL = window.SUPABASE_URL || "";
  var SUPABASE_ANON_KEY = window.SUPABASE_ANON_KEY || "";
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !window.supabase) return;
  var sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  window.__authClient = sb;

  function redirectToLogin() {
    var next = encodeURIComponent(window.location.pathname + window.location.search);
    window.location.replace("login.html?next=" + next);
  }

  function injectUserControl(user) {
    var actions = document.querySelector(".ds-topbar__actions");
    if (!actions || document.getElementById("authUserChip")) return;
    var profileBtn = document.createElement("a");
    profileBtn.id = "authUserChip";
    profileBtn.href = "profile.html";
    profileBtn.className = "ico-btn";
    profileBtn.title = user.email || "Profile";
    if (window.icon) profileBtn.innerHTML = window.icon("user", 18);
    var logoutBtn = document.createElement("button");
    logoutBtn.className = "ico-btn";
    logoutBtn.title = "ออกจากระบบ";
    if (window.icon) logoutBtn.innerHTML = window.icon("logout", 18);
    logoutBtn.addEventListener("click", function () {
      sb.auth.signOut().then(function () { window.location.replace("login.html"); });
    });
    actions.appendChild(profileBtn);
    actions.appendChild(logoutBtn);
  }

  sb.auth.getSession().then(function (res) {
    var session = res.data && res.data.session;
    if (!session) { redirectToLogin(); return; }
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", function () { injectUserControl(session.user); });
    } else {
      injectUserControl(session.user);
    }
  });

  sb.auth.onAuthStateChange(function (event) {
    if (event === "SIGNED_OUT") redirectToLogin();
  });
})();
