/* Red Team Rating — visual enhancements only. All content renders without JS. */
(function () {
  var d = document;
  d.documentElement.classList.add('rtr-js');

  // Mobile nav toggle
  var btn = d.querySelector('.rtr-nav-toggle');
  var nav = d.querySelector('.rtr-nav');
  if (btn && nav) {
    btn.addEventListener('click', function () {
      var open = btn.getAttribute('aria-expanded') === 'true';
      btn.setAttribute('aria-expanded', String(!open));
      btn.setAttribute('aria-label', open ? 'Открыть меню' : 'Закрыть меню');
      nav.classList.toggle('is-open');
    });
  }

  // Anchor pills: fade edges only while pills are hidden on that side
  var strip = d.querySelector('.rtr-subnav__scroll');
  if (strip) {
    var edges = function () {
      var max = strip.scrollWidth - strip.clientWidth;
      strip.classList.toggle('is-more-left', strip.scrollLeft > 2);
      strip.classList.toggle('is-more-right', max > 2 && strip.scrollLeft < max - 2);
    };
    strip.addEventListener('scroll', edges, { passive: true });
    window.addEventListener('resize', edges);
    edges();
  }

  // Back to top: show after one screen of scrolling
  var totop = d.querySelector('.rtr-totop');
  if (totop) {
    var toggleTop = function () { totop.classList.toggle('is-visible', window.scrollY > window.innerHeight); };
    window.addEventListener('scroll', toggleTop, { passive: true });
    toggleTop();
    // Native jump to #top (on <body>); just keep the URL clean afterwards
    totop.addEventListener('click', function () {
      setTimeout(function () {
        if (history.replaceState) history.replaceState(null, '', location.pathname + location.search);
      }, 0);
    });
  }

  if (!('IntersectionObserver' in window)) return;

  // Active step in "7 stages" + matching MITRE tactics row
  var steps = d.querySelectorAll('.rtr-step');
  if (steps.length) {
    var rows = d.querySelectorAll('.rtr-tactics__row');
    var stepIO = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (!e.isIntersecting) return;
        steps.forEach(function (s) { s.classList.toggle('is-active', s === e.target); });
        var n = e.target.getAttribute('data-step');
        rows.forEach(function (r) { r.classList.toggle('is-active', r.getAttribute('data-step') === n); });
      });
    }, { rootMargin: '-45% 0px -50% 0px' });
    steps.forEach(function (s) { stepIO.observe(s); });
  }

  // Anchor pills: highlight current section
  var pills = d.querySelectorAll('.rtr-subnav__link');
  if (pills.length) {
    var map = {};
    pills.forEach(function (p) { map[p.getAttribute('href').slice(1)] = p; });
    var secIO = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (!e.isIntersecting) return;
        var p = map[e.target.id];
        if (!p) return;
        pills.forEach(function (x) { x.classList.toggle('is-active', x === p); });
        var sc = p.parentNode;
        sc.scrollTo({ left: p.offsetLeft - 16, behavior: 'smooth' });
      });
    }, { rootMargin: '-30% 0px -65% 0px' });
    Object.keys(map).forEach(function (id) { var s = d.getElementById(id); if (s) secIO.observe(s); });
  }

})();
