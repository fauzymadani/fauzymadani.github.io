document.addEventListener("DOMContentLoaded", function () {
  var container = document.getElementById("content") || document.body;
  var headings = container.querySelectorAll("h2, h3");

  if (headings.length < 2) return; // skip toc for short posts

  var toc = document.createElement("nav");
  toc.id = "toc";

  var title = document.createElement("div");
  title.id = "toc-title";
  title.textContent = "Contents";
  toc.appendChild(title);

  var list = document.createElement("ul");
  headings.forEach(function (h, i) {
    if (!h.id) h.id = "section-" + i;

    var li = document.createElement("li");
    if (h.tagName === "H3") li.className = "toc-h3";

    var a = document.createElement("a");
    a.href = "#" + h.id;
    a.textContent = h.textContent;

    li.appendChild(a);
    list.appendChild(li);
  });
  toc.appendChild(list);

  document.body.appendChild(toc);
});
