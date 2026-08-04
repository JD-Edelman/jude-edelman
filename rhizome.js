/* Rhizome map of theoretical influences.
 *
 * Reads the plain list in #rz-index and draws it as a map: no root, no ordering,
 * every point connectable to every other. Nothing here needs editing to change
 * the content — edit the list in rhizome.html instead.
 *
 * No dependencies, no build step, to match the rest of the site.
 */
(function () {
  'use strict';

  var svg = document.getElementById('rz-svg');
  var canvas = document.getElementById('rz-canvas');
  var source = document.querySelectorAll('.rz-source > li');
  if (!svg || !canvas || !source.length) return;

  var edgeLayer = document.getElementById('rz-edges');
  var nodeLayer = document.getElementById('rz-nodes');
  var plateau = document.getElementById('rz-plateau');
  var statusEl = document.getElementById('rz-status');
  var controls = document.getElementById('rz-controls');

  var W = 1000, H = 660;
  var PAD_X = 120, PAD_Y = 46;
  var SVG_NS = 'http://www.w3.org/2000/svg';

  /* A phone gets a portrait canvas: the same map, given room to breathe
     downwards instead of being squeezed sideways. */
  function preferredHeight() {
    var w = window.innerWidth || 1024;
    if (isCompact()) return 1400;
    if (w < 900) return 1150;
    return 1000;
  }

  /* Fifteen names cannot all be legible at once on a phone. Below this width
     the map keeps its points but shows only the names where you are standing,
     and the full text is a scroll away regardless. */
  function isCompact() {
    return (window.innerWidth || 1024) <= 620;
  }

  var REST = { lineage: 165, alliance: 150, shared: 190, tension: 245, new: 205 };
  /* Most relations read the same from either end. Lineage does not: it is
     declared on the earlier thinker, so it reverses depending on where you
     are standing. */
  var REL_WORD = {
    lineage: 'gives rise to',
    alliance: 'works the same seam as',
    tension: 'pulls against',
    shared: 'meets on common ground with',
    new: 'a line that grew'
  };

  function relWord(e, from) {
    if (e.rel === 'lineage') return from === e.b ? 'grows out of' : 'gives rise to';
    return REL_WORD[e.rel] || e.rel;
  }

  /* ---- read the list ------------------------------------------------- */

  var nodes = [];
  var byKey = {};

  Array.prototype.forEach.call(source, function (li) {
    var key = li.id.replace(/^rz-/, '');
    var name = li.querySelector('h3');
    var work = li.querySelector('.rz-work');
    var gloss = li.querySelector('.rz-gloss');
    var node = {
      key: key,
      name: name ? name.textContent.trim() : key,
      work: work ? work.innerHTML : '',
      gloss: gloss ? gloss.textContent.trim() : '',
      raw: li.getAttribute('data-links') || '',
      x: 0, y: 0, vx: 0, vy: 0, fixed: false
    };
    nodes.push(node);
    byKey[key] = node;
  });

  var edges = [];
  var seen = {};

  function addEdge(a, b, rel, sprouted) {
    if (a === b || !byKey[a] || !byKey[b]) return null;
    var id = a < b ? a + '~' + b : b + '~' + a;
    if (seen[id]) return null;
    var e = { id: id, a: a, b: b, rel: rel, cut: false, sprouted: !!sprouted };
    seen[id] = e;
    edges.push(e);
    return e;
  }

  nodes.forEach(function (n) {
    n.raw.split(',').forEach(function (part) {
      part = part.trim();
      if (!part) return;
      var bits = part.split('|');
      var target = bits[0].trim();
      var rel = (bits[1] || 'shared').trim();
      if (!byKey[target]) {
        if (window.console) console.warn('rhizome: unknown link target "' + target + '" on ' + n.key);
        return;
      }
      addEdge(n.key, target, rel);
    });
  });

  function activeEdges() {
    return edges.filter(function (e) { return !e.cut; });
  }

  function edgesFor(key) {
    return edges.filter(function (e) { return e.a === key || e.b === key; });
  }

  function other(e, key) {
    return e.a === key ? e.b : e.a;
  }

  /* ---- layout --------------------------------------------------------- */

  /* Seeded so the map is the same map on every visit; only the point you
     enter at changes. */
  function mulberry32(seed) {
    return function () {
      seed |= 0; seed = seed + 0x6D2B79F5 | 0;
      var t = Math.imul(seed ^ seed >>> 15, 1 | seed);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }

  function seedPositions() {
    var rand = mulberry32(20260804);
    var cx = W / 2, cy = H / 2;
    nodes.forEach(function (n, i) {
      var a = (i / nodes.length) * Math.PI * 2;
      var r = 210 + rand() * 90;
      n.x = cx + Math.cos(a) * r * 1.25 + (rand() - 0.5) * 60;
      n.y = cy + Math.sin(a) * r * 0.8 + (rand() - 0.5) * 60;
      n.vx = n.vy = 0;
    });
  }

  function tick() {
    var i, j, a, b, dx, dy, d, f;

    /* Points repel as flat ellipses rather than circles: a name is much wider
       than it is tall, so two points sharing a line push each other apart
       harder than two points sitting one above the other. Keeps labels from
       colliding without a separate de-collision pass. */
    var SQUASH = 1.9;
    /* Every point pushes every other, so the total shove on any one of them
       grows with the size of the map. Scaling by the count keeps a crowded
       map from flattening itself against the edges. */
    var rep = 54000 * (15 / nodes.length);

    for (i = 0; i < nodes.length; i++) {
      for (j = i + 1; j < nodes.length; j++) {
        a = nodes[i]; b = nodes[j];
        dx = b.x - a.x; dy = b.y - a.y;
        var sy = dy * SQUASH;
        d = Math.sqrt(dx * dx + sy * sy) || 0.01;
        f = Math.min(rep / (d * d), 3.2);
        dx = dx / d * f; dy = sy / d * f;
        a.vx -= dx; a.vy -= dy;
        b.vx += dx; b.vy += dy;
      }
    }

    activeEdges().forEach(function (e) {
      var p = byKey[e.a], q = byKey[e.b];
      var ex = q.x - p.x, ey = q.y - p.y;
      var ed = Math.sqrt(ex * ex + ey * ey) || 0.01;
      var rest = REST[e.rel] || 190;
      var k = (ed - rest) * 0.012;
      ex = ex / ed * k; ey = ey / ed * k;
      p.vx += ex; p.vy += ey;
      q.vx -= ex; q.vy -= ey;
    });

    /* A soft verge inside the hard edge. Without it a crowded map presses its
       outermost points flat against the boundary in straight lines, which
       reads as a box rather than a spread. */
    var VERGE = 80;

    nodes.forEach(function (n) {
      n.vx += (W / 2 - n.x) * 0.0011;
      n.vy += (H / 2 - n.y) * 0.0016;

      if (n.x < PAD_X + VERGE) n.vx += (PAD_X + VERGE - n.x) * 0.018;
      if (n.x > W - PAD_X - VERGE) n.vx -= (n.x - (W - PAD_X - VERGE)) * 0.018;
      if (n.y < PAD_Y + VERGE) n.vy += (PAD_Y + VERGE - n.y) * 0.018;
      if (n.y > H - PAD_Y - VERGE) n.vy -= (n.y - (H - PAD_Y - VERGE)) * 0.018;

      if (n.fixed) { n.vx = n.vy = 0; return; }
      n.vx *= 0.86; n.vy *= 0.86;
      n.x += Math.max(-14, Math.min(14, n.vx));
      n.y += Math.max(-14, Math.min(14, n.vy));
      n.x = Math.max(PAD_X, Math.min(W - PAD_X, n.x));
      n.y = Math.max(PAD_Y, Math.min(H - PAD_Y, n.y));
    });
  }

  function settle(steps) {
    for (var i = 0; i < steps; i++) tick();
  }

  /* ---- render --------------------------------------------------------- */

  var edgeEls = {};
  var nodeEls = {};

  function buildEdge(e) {
    var line = document.createElementNS(SVG_NS, 'line');
    line.setAttribute('class', 'rz-edge');
    line.setAttribute('data-rel', e.rel);
    line.setAttribute('data-id', e.id);
    edgeLayer.appendChild(line);
    edgeEls[e.id] = line;
  }

  function buildNode(n) {
    var g = document.createElementNS(SVG_NS, 'g');
    g.setAttribute('class', 'rz-node');
    g.setAttribute('data-key', n.key);
    g.setAttribute('tabindex', '0');
    g.setAttribute('role', 'button');

    /* An invisible disc so the point is reachable by a finger, not just a cursor. */
    var hit = document.createElementNS(SVG_NS, 'circle');
    hit.setAttribute('class', 'rz-hit');
    hit.setAttribute('r', '20');

    var c = document.createElementNS(SVG_NS, 'circle');
    c.setAttribute('class', 'rz-dot');
    c.setAttribute('r', '4.5');

    var t = document.createElementNS(SVG_NS, 'text');
    t.setAttribute('dy', '0.35em');
    t.textContent = n.name;

    g.appendChild(hit);
    g.appendChild(c);
    g.appendChild(t);
    nodeLayer.appendChild(g);
    nodeEls[n.key] = { g: g, circle: c, text: t };
  }

  edges.forEach(buildEdge);
  nodes.forEach(buildNode);

  function draw() {
    var compact = isCompact();

    edges.forEach(function (e) {
      var el = edgeEls[e.id];
      if (!el) return;
      var p = byKey[e.a], q = byKey[e.b];
      el.setAttribute('x1', p.x); el.setAttribute('y1', p.y);
      el.setAttribute('x2', q.x); el.setAttribute('y2', q.y);
      el.setAttribute('data-rel', e.rel);
      el.classList.toggle('is-cut', e.cut);
    });

    nodes.forEach(function (n) {
      var el = nodeEls[n.key];
      el.g.setAttribute('transform', 'translate(' + n.x + ',' + n.y + ')');
      var left = n.x > W * 0.56;
      el.text.setAttribute('x', left ? -12 : 12);
      el.text.setAttribute('text-anchor', left ? 'end' : 'start');
      if (!compact) el.text.setAttribute('dy', '0.35em');
      el.g.setAttribute('aria-label', n.name + ', ' +
        edgesFor(n.key).filter(function (e) { return !e.cut; }).length + ' connections');
    });

    if (compact) stackVisibleLabels();
  }

  /* ---- keeping names off each other ----------------------------------- */

  /* The force model treats points as points, but what collides on screen is
     the names. Measure the rendered labels and push overlapping pairs apart
     along whichever axis needs the least movement. */
  function labelBox(n) {
    /* When most names are hidden there is nothing to keep apart but the
       points themselves. */
    var w = isCompact() ? 26 : (n.labelWidth || 0);
    var left = n.x > W * 0.56;
    return {
      x0: left ? n.x - 12 - w : n.x - 8,
      x1: left ? n.x + 8 : n.x + 12 + w,
      y0: n.y - 11,
      y1: n.y + 11
    };
  }

  var fontUnits = 15;

  function measureLabels() {
    nodes.forEach(function (n) {
      var t = nodeEls[n.key].text;
      n.labelWidth = t.getComputedTextLength ? t.getComputedTextLength() : n.name.length * 7;
    });
    if (nodes.length && window.getComputedStyle) {
      var size = parseFloat(window.getComputedStyle(nodeEls[nodes[0].key].text).fontSize);
      if (size) fontUnits = size;
    }
  }

  /* In compact mode the nodes stay put and only a handful of names are shown,
     so collisions are settled by moving the words rather than the points. */
  function stackVisibleLabels() {
    var vis = [];
    nodes.forEach(function (n) {
      var cl = nodeEls[n.key].g.classList;
      if (cl.contains('is-live') || cl.contains('is-near')) vis.push(n);
    });
    vis.sort(function (a, b) { return a.y - b.y; });

    var lineHeight = fontUnits * 1.25;
    var placed = [];

    vis.forEach(function (n) {
      var w = n.labelWidth || 0;
      var left = n.x > W * 0.56;
      var x0 = left ? n.x - 12 - w : n.x - 8;
      var x1 = left ? n.x + 8 : n.x + 12 + w;
      var off = 0;
      placed.forEach(function (p) {
        if (x0 >= p.x1 || p.x0 >= x1) return;
        var mine = n.y + off;
        if (Math.abs(mine - p.y) < lineHeight) off += (p.y + lineHeight) - mine;
      });
      placed.push({ x0: x0, x1: x1, y: n.y + off });
      nodeEls[n.key].text.setAttribute('dy', (fontUnits * 0.35 + off).toFixed(1));
    });
  }

  function relaxLabels(passes) {
    var GAP_X = 10, GAP_Y = 6;
    for (var pass = 0; pass < passes; pass++) {
      var moved = false;
      for (var i = 0; i < nodes.length; i++) {
        for (var j = i + 1; j < nodes.length; j++) {
          var a = nodes[i], b = nodes[j];
          var ba = labelBox(a), bb = labelBox(b);
          var ox = Math.min(ba.x1, bb.x1) - Math.max(ba.x0, bb.x0) + GAP_X;
          var oy = Math.min(ba.y1, bb.y1) - Math.max(ba.y0, bb.y0) + GAP_Y;
          if (ox <= 0 || oy <= 0) continue;
          moved = true;
          /* Names are wide and short, so separating them vertically is
             almost always the shorter trip. */
          if (oy <= ox * 0.6) {
            var sy = (a.y <= b.y ? -1 : 1) * oy / 2;
            if (!a.fixed) a.y += sy;
            if (!b.fixed) b.y -= sy;
          } else {
            var sx = (a.x <= b.x ? -1 : 1) * ox / 2;
            if (!a.fixed) a.x += sx;
            if (!b.fixed) b.x -= sx;
          }
          a.x = Math.max(PAD_X, Math.min(W - PAD_X, a.x));
          a.y = Math.max(PAD_Y, Math.min(H - PAD_Y, a.y));
          b.x = Math.max(PAD_X, Math.min(W - PAD_X, b.x));
          b.y = Math.max(PAD_Y, Math.min(H - PAD_Y, b.y));
        }
      }
      if (!moved) break;
    }
  }

  function tidy() {
    measureLabels();
    relaxLabels(40);
    draw();
  }

  /* ---- highlighting and the plateau panel ----------------------------- */

  var selected = null;
  var hovered = null;

  function live() { return hovered || selected; }

  function paint() {
    var key = live();
    /* Only narrowing the field — hovering or tabbing — dims the rest. The point
       you happen to be standing on is lit, but the whole map stays readable. */
    svg.classList.toggle('rz-svg-dimmed', !!hovered);

    var near = {};
    if (key) {
      edgesFor(key).forEach(function (e) {
        if (!e.cut) near[other(e, key)] = true;
      });
    }

    nodes.forEach(function (n) {
      var el = nodeEls[n.key];
      el.g.classList.toggle('is-live', n.key === key);
      el.g.classList.toggle('is-near', !!near[n.key]);
    });

    edges.forEach(function (e) {
      var el = edgeEls[e.id];
      if (!el) return;
      el.classList.toggle('is-live', !!key && !e.cut && (e.a === key || e.b === key));
    });

    if (isCompact()) stackVisibleLabels();
  }

  function say(msg) {
    if (statusEl) statusEl.textContent = msg || '';
  }

  function renderPlateau() {
    if (!plateau) return;
    var n = byKey[selected];
    if (!n) { plateau.hidden = true; return; }
    plateau.hidden = false;
    plateau.innerHTML = '';

    var h = document.createElement('h3');
    h.textContent = n.name;
    plateau.appendChild(h);

    if (n.work) {
      var w = document.createElement('p');
      w.className = 'rz-work';
      w.innerHTML = n.work;
      plateau.appendChild(w);
    }

    var g = document.createElement('p');
    g.className = 'rz-gloss';
    g.textContent = n.gloss;
    plateau.appendChild(g);

    var mine = edgesFor(n.key);
    var label = document.createElement('p');
    label.className = 'rz-conn-label';
    label.textContent = mine.length ? 'Lines from here' : 'No lines from here yet';
    plateau.appendChild(label);

    var ul = document.createElement('ul');
    ul.className = 'rz-conns';

    mine.forEach(function (e) {
      var li = document.createElement('li');
      li.classList.toggle('is-severed', e.cut);

      var rel = document.createElement('span');
      rel.className = 'rz-rel';
      rel.textContent = e.cut ? 'cut' : relWord(e, n.key);
      li.appendChild(rel);

      var go = document.createElement('button');
      go.type = 'button';
      go.className = 'rz-goto';
      go.textContent = byKey[other(e, n.key)].name;
      go.addEventListener('click', function () { select(other(e, n.key)); });
      li.appendChild(go);

      var cut = document.createElement('button');
      cut.type = 'button';
      cut.className = 'rz-sever';
      cut.textContent = e.cut ? 'restore' : 'cut';
      cut.addEventListener('click', function () {
        e.cut ? restore(e) : sever(e);
      });
      li.appendChild(cut);

      ul.appendChild(li);
    });

    plateau.appendChild(ul);
  }

  function select(key) {
    selected = byKey[key] ? key : null;
    renderPlateau();
    paint();
  }

  /* ---- asignifying rupture -------------------------------------------- */

  /* "A rhizome may be broken, shattered at a given spot, but it will start up
     again on one of its old lines, or on new lines." Cutting a line grows one
     somewhere else — preferring an endpoint of the line just cut. */
  function sprout(fromCut) {
    var candidates = [];
    nodes.forEach(function (p) {
      nodes.forEach(function (q) {
        if (p.key >= q.key) return;
        var id = p.key + '~' + q.key;
        if (seen[id]) return;
        var touches = fromCut &&
          (p.key === fromCut.a || p.key === fromCut.b || q.key === fromCut.a || q.key === fromCut.b);
        candidates.push({ a: p.key, b: q.key, weight: touches ? 4 : 1 });
      });
    });
    if (!candidates.length) return null;

    var total = candidates.reduce(function (s, c) { return s + c.weight; }, 0);
    var pick = Math.random() * total;
    var chosen = candidates[candidates.length - 1];
    for (var i = 0; i < candidates.length; i++) {
      pick -= candidates[i].weight;
      if (pick <= 0) { chosen = candidates[i]; break; }
    }

    var e = addEdge(chosen.a, chosen.b, 'new', true);
    if (e) buildEdge(e);
    return e;
  }

  function sever(e) {
    e.cut = true;
    var grown = sprout(e);
    say(grown
      ? 'A line was cut between ' + byKey[e.a].name + ' and ' + byKey[e.b].name +
        '. Another has grown between ' + byKey[grown.a].name + ' and ' + byKey[grown.b].name + '.'
      : 'A line was cut between ' + byKey[e.a].name + ' and ' + byKey[e.b].name +
        '. Every point is already connected to every other; nothing new can grow.');
    renderPlateau();
    paint();
    reheat();
  }

  function restore(e) {
    e.cut = false;
    say('The line between ' + byKey[e.a].name + ' and ' + byKey[e.b].name + ' is back.');
    renderPlateau();
    paint();
    reheat();
  }

  function regrow() {
    edges = edges.filter(function (e) {
      if (e.sprouted) {
        delete seen[e.id];
        if (edgeEls[e.id]) {
          edgeLayer.removeChild(edgeEls[e.id]);
          delete edgeEls[e.id];
        }
        return false;
      }
      e.cut = false;
      return true;
    });
    nodes.forEach(function (n) { n.fixed = false; });
    seedPositions();
    settle(700);
    tidy();
    say('The map is back to where it started.');
    renderPlateau();
    paint();
  }

  /* ---- motion --------------------------------------------------------- */

  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var frames = 0;
  var running = false;

  function loop() {
    tick();
    draw();
    frames--;
    if (frames > 0) {
      requestAnimationFrame(loop);
    } else {
      running = false;
    }
  }

  function reheat() {
    if (reduce) { settle(120); draw(); return; }
    frames = 90;
    if (!running) { running = true; requestAnimationFrame(loop); }
  }

  /* ---- pointer and keyboard ------------------------------------------- */

  function svgPoint(evt) {
    var rect = svg.getBoundingClientRect();
    return {
      x: (evt.clientX - rect.left) / rect.width * W,
      y: (evt.clientY - rect.top) / rect.height * H
    };
  }

  nodes.forEach(function (n) {
    var el = nodeEls[n.key];
    var drag = null;

    el.g.addEventListener('pointerenter', function () { hovered = n.key; paint(); });
    el.g.addEventListener('pointerleave', function () {
      if (hovered === n.key) { hovered = null; paint(); }
    });

    el.g.addEventListener('pointerdown', function (evt) {
      evt.preventDefault();
      var p = svgPoint(evt);
      drag = { dx: n.x - p.x, dy: n.y - p.y, moved: false };
      el.g.classList.add('is-dragging');
      el.g.setPointerCapture(evt.pointerId);
    });

    el.g.addEventListener('pointermove', function (evt) {
      if (!drag) return;
      var p = svgPoint(evt);
      var nx = p.x + drag.dx, ny = p.y + drag.dy;
      if (Math.abs(nx - n.x) + Math.abs(ny - n.y) > 3) drag.moved = true;
      n.x = Math.max(PAD_X, Math.min(W - PAD_X, nx));
      n.y = Math.max(PAD_Y, Math.min(H - PAD_Y, ny));
      n.vx = n.vy = 0;
      n.fixed = true;
      reheat();
      draw();
    });

    function endDrag(evt) {
      if (!drag) return;
      el.g.classList.remove('is-dragging');
      if (evt.pointerId !== undefined && el.g.hasPointerCapture(evt.pointerId)) {
        el.g.releasePointerCapture(evt.pointerId);
      }
      /* A press that did not move is a choice of where to stand. */
      if (!drag.moved) { n.fixed = false; select(n.key); }
      drag = null;
    }

    el.g.addEventListener('pointerup', endDrag);
    el.g.addEventListener('pointercancel', endDrag);

    el.g.addEventListener('focus', function () { hovered = n.key; paint(); });
    el.g.addEventListener('blur', function () {
      if (hovered === n.key) { hovered = null; paint(); }
    });
    el.g.addEventListener('keydown', function (evt) {
      if (evt.key === 'Enter' || evt.key === ' ') {
        evt.preventDefault();
        select(n.key);
      }
    });
  });

  /* ---- start ----------------------------------------------------------- */

  var hint = document.querySelector('.rz-hint');

  function relayout() {
    H = preferredHeight();
    svg.setAttribute('viewBox', '0 0 ' + W + ' ' + H);
    canvas.classList.toggle('rz-compact', isCompact());
    if (hint) {
      hint.textContent = isCompact()
        ? 'Tap a point to stand there. Drag to remake the map.'
        : 'Hover or tab through the points. Drag to remake the map. Cut a line from the panel below.';
    }
    nodes.forEach(function (n) { n.fixed = false; });
    seedPositions();
    settle(700);
    tidy();
    paint();
  }

  /* Labels can only be measured once the map is on screen, so it is revealed
     before the first layout rather than after it. */
  canvas.hidden = false;
  if (controls) controls.hidden = false;
  relayout();

  /* Measured again once the real typeface has replaced the fallback. */
  if (document.fonts && document.fonts.ready) {
    document.fonts.ready.then(tidy).catch(function () {});
  }

  /* Rotating a phone changes which shape the map should be. */
  var resizeTimer = null;
  var lastH = H;
  window.addEventListener('resize', function () {
    if (preferredHeight() === lastH) return;
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function () {
      lastH = preferredHeight();
      relayout();
    }, 180);
  });

  var regrowBtn = document.getElementById('rz-regrow');
  var shuffleBtn = document.getElementById('rz-shuffle');
  if (regrowBtn) regrowBtn.addEventListener('click', regrow);
  if (shuffleBtn) shuffleBtn.addEventListener('click', function () {
    var pool = nodes.filter(function (n) { return n.key !== selected; });
    if (pool.length) select(pool[Math.floor(Math.random() * pool.length)].key);
  });

  /* Always in the middle: every visit opens at a different point. */
  select(nodes[Math.floor(Math.random() * nodes.length)].key);
  say('You have entered the map at ' + byKey[selected].name + '. There is no first point.');
  draw();
})();
