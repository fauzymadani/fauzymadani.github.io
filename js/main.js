/**
 * some JavaScript code for this blog theme
 */
/* jshint asi:true */

/////////////////////////header////////////////////////////
/**
 * clickMenu
 */
(function() {
  var themeToggle = document.querySelector('#themeToggle')
  var root = document.documentElement
  var storedTheme = localStorage.getItem('theme')

  function applyTheme(theme) {
    root.setAttribute('data-theme', theme)
    themeToggle.setAttribute('aria-pressed', theme === 'dark' ? 'true' : 'false')
    themeToggle.innerHTML = theme === 'dark'
      ? '<i class="fa fa-sun-o" aria-hidden="true"></i>'
      : '<i class="fa fa-moon-o" aria-hidden="true"></i>'
  }

  if (themeToggle !== null) {
    var initialTheme = storedTheme || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
    applyTheme(initialTheme)
    themeToggle.addEventListener('click', function() {
      var nextTheme = root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark'
      localStorage.setItem('theme', nextTheme)
      applyTheme(nextTheme)
    })
  }
}());

(function() {
  if (window.innerWidth <= 770) {
    var menuBtn = document.querySelector('#headerMenu')
    var nav = document.querySelector('#headerNav')
    menuBtn.onclick = function(e) {
      e.stopPropagation()
      if (menuBtn.classList.contains('active')) {
        menuBtn.classList.remove('active')
        nav.classList.remove('nav-show')
      } else {
        nav.classList.add('nav-show')
        menuBtn.classList.add('active')
      }
    }
    document.querySelector('body').addEventListener('click', function() {
      nav.classList.remove('nav-show')
      menuBtn.classList.remove('active')
    })
  }
}());

//////////////////////////back to top////////////////////////////
(function() {
  var backToTop = document.querySelector('.back-to-top')
  var backToTopA = document.querySelector('.back-to-top a')
  // console.log(backToTop);
  window.addEventListener('scroll', function() {

    // 页面顶部滚进去的距离
    var scrollTop = Math.max(document.documentElement.scrollTop, document.body.scrollTop)

    if (scrollTop > 200) {
      backToTop.classList.add('back-to-top-show')
    } else {
      backToTop.classList.remove('back-to-top-show')
    }
  })

  backToTopA.addEventListener('click',function (e) {
      e.preventDefault()
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
    })
  })
}());

//////////////////////////hover on demo//////////////////////////////
(function() {
  var demoItems = document.querySelectorAll('.grid-item')
}());

//////////////////////////protected email////////////////////////////
(function() {
  var emailLinks = document.querySelectorAll('.protected-email')

  for (var i = 0; i < emailLinks.length; i++) {
    var link = emailLinks[i]
    var address = link.getAttribute('data-email-user') + '@' + link.getAttribute('data-email-domain')

    link.href = 'mailto:' + address
    link.setAttribute('aria-label', 'Email ' + address)
    link.classList.add('protected-email-ready')
  }
}());

