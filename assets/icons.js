// Engineering Daily Issue Log — shared icon set
// Original line-icon constructions in the Tabler/Lucide visual language
// (24x24 viewBox, 2px stroke, round caps/joins, no fill) — not copied path data.
// Usage: icon("search", 18) returns an <svg>...</svg> string.

window.ICONS = {
  search: '<circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>',
  plus: '<line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>',
  edit: '<path d="M17 3a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4L17 3z"/>',
  trash: '<path d="M4 7h16"/><path d="M9 7V4h6v3"/><path d="M6 7l1 13h10l1-13"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/>',
  x: '<line x1="6" y1="6" x2="18" y2="18"/><line x1="6" y1="18" x2="18" y2="6"/>',
  bell: '<path d="M6 8a6 6 0 1 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10 21a2 2 0 0 0 4 0"/>',
  settings: '<circle cx="12" cy="12" r="3"/><path d="M12 3v3M12 18v3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M3 12h3M18 12h3M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1"/>',
  calendar: '<rect x="3" y="5" width="18" height="16" rx="2"/><line x1="3" y1="10" x2="21" y2="10"/><line x1="8" y1="3" x2="8" y2="7"/><line x1="16" y1="3" x2="16" y2="7"/>',
  moon: '<path d="M21 12.8A9 9 0 1 1 11.2 3 7 7 0 0 0 21 12.8z"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
  chartBar: '<line x1="6" y1="20" x2="6" y2="12"/><line x1="12" y1="20" x2="12" y2="8"/><line x1="18" y1="20" x2="18" y2="4"/>',
  chartPie: '<circle cx="12" cy="12" r="9"/><path d="M12 3v9l7 4"/>',
  trendingUp: '<polyline points="3 17 9 11 13 15 21 7"/><polyline points="14 7 21 7 21 14"/>',
  trendingDown: '<polyline points="3 7 9 13 13 9 21 17"/><polyline points="14 17 21 17 21 10"/>',
  alertTriangle: '<path d="M12 3L2 21h20L12 3z"/><line x1="12" y1="9" x2="12" y2="14"/><circle cx="12" cy="17.3" r="1" fill="currentColor" stroke="none"/>',
  checkCircle: '<circle cx="12" cy="12" r="9"/><polyline points="8 12 11 15 16 9"/>',
  clock: '<circle cx="12" cy="12" r="9"/><polyline points="12 7 12 12 15 14"/>',
  filter: '<path d="M4 4h16l-6 8v6l-4 2v-8L4 4z"/>',
  download: '<path d="M12 3v12"/><polyline points="7 10 12 15 17 10"/><line x1="5" y1="21" x2="19" y2="21"/>',
  paperclip: '<path d="M21 11.5l-8.5 8.5a4 4 0 0 1-5.7-5.7l9-9a2.7 2.7 0 0 1 3.8 3.8l-8.5 8.5a1.3 1.3 0 0 1-1.9-1.9l7.4-7.4"/>',
  user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/>',
  users: '<circle cx="9" cy="8" r="3.2"/><path d="M2.5 20c0-3.3 2.9-5 6.5-5s6.5 1.7 6.5 5"/><path d="M16 4.3a3.2 3.2 0 0 1 0 6.2"/><path d="M18 15.2c2.6.5 4 1.8 4 4.8"/>',
  home: '<path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/>',
  layoutDashboard: '<rect x="3" y="3" width="7" height="9" rx="1"/><rect x="14" y="3" width="7" height="5" rx="1"/><rect x="14" y="12" width="7" height="9" rx="1"/><rect x="3" y="16" width="7" height="5" rx="1"/>',
  bookOpen: '<path d="M12 6.5c-2-1.5-5-2-8-1.5v13c3-.5 6 0 8 1.5c2-1.5 5-2 8-1.5v-13c-3-.5-6 0-8 1.5z"/><line x1="12" y1="6.5" x2="12" y2="19.5"/>',
  folder: '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7z"/>',
  fileText: '<path d="M6 2h9l5 5v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2z"/><polyline points="15 2 15 7 20 7"/><line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="16" y2="17"/><line x1="8" y1="9" x2="10" y2="9"/>',
  printer: '<path d="M6 9V3h12v6"/><rect x="4" y="9" width="16" height="8" rx="1"/><path d="M6 17h12v5H6z"/>',
  chevronDown: '<polyline points="6 9 12 15 18 9"/>',
  chevronRight: '<polyline points="9 6 15 12 9 18"/>',
  arrowRight: '<line x1="4" y1="12" x2="20" y2="12"/><polyline points="13 5 20 12 13 19"/>',
  refresh: '<path d="M21 12a9 9 0 1 1-3-6.7"/><polyline points="21 3 21 9 15 9"/>',
  camera: '<path d="M4 8a2 2 0 0 1 2-2h1l1.5-2h7L17 6h1a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V8z"/><circle cx="12" cy="13" r="4"/>',
  info: '<circle cx="12" cy="12" r="9"/><line x1="12" y1="11" x2="12" y2="16"/><circle cx="12" cy="7.5" r="1" fill="currentColor" stroke="none"/>',
  factory: '<path d="M3 21V10l6 4v-4l6 4V7l6 4v10H3z"/><line x1="7" y1="21" x2="7" y2="17"/><line x1="13" y1="21" x2="13" y2="17"/>',
  flame: '<path d="M12 2c1 4-3 5-3 9a3 3 0 0 0 6 0c0-1-1-2-1-3 2 1 3 3 3 5a5 5 0 0 1-10 0c0-5 3-6 5-11z"/>',
  pause: '<circle cx="12" cy="12" r="9"/><line x1="8" y1="12" x2="16" y2="12"/>',
  target: '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4"/><circle cx="12" cy="12" r=".8" fill="currentColor" stroke="none"/>',
  externalLink: '<path d="M14 3h7v7"/><line x1="21" y1="3" x2="10" y2="14"/><path d="M21 14v5a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h5"/>',
  lightbulb: '<path d="M9 18h6"/><path d="M10 21h4"/><path d="M12 3a6 6 0 0 0-4 10.5c.6.6 1 1.5 1 2.5h6c0-1 .4-1.9 1-2.5A6 6 0 0 0 12 3z"/>',
  presentation: '<rect x="3" y="4" width="18" height="12" rx="1"/><line x1="8" y1="20" x2="16" y2="20"/><line x1="12" y1="16" x2="12" y2="20"/>',
  building: '<rect x="4" y="3" width="16" height="18" rx="1"/><line x1="8" y1="7" x2="8" y2="7.01"/><line x1="12" y1="7" x2="12" y2="7.01"/><line x1="16" y1="7" x2="16" y2="7.01"/><line x1="8" y1="11" x2="8" y2="11.01"/><line x1="12" y1="11" x2="12" y2="11.01"/><line x1="16" y1="11" x2="16" y2="11.01"/><line x1="8" y1="15" x2="16" y2="15"/>',
  logout: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>',
  check: '<polyline points="20 6 9 17 4 12"/>',
  minus: '<line x1="5" y1="12" x2="19" y2="12"/>',
  wrench: '<path d="M14.7 6.3a4 4 0 0 1-5.6 5.6L4 17l3 3 5.1-5.1a4 4 0 0 1 5.6-5.6l-3-3z"/>',
  coin: '<circle cx="12" cy="12" r="9"/><path d="M9.5 15.5c0 1 1 1.5 2.5 1.5s2.5-.6 2.5-1.6c0-2.4-5-1-5-3.4 0-1 1-1.6 2.5-1.6s2.5.5 2.5 1.5"/><line x1="12" y1="7.5" x2="12" y2="9"/><line x1="12" y1="15" x2="12" y2="16.5"/>',
  circleDot: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="3" fill="currentColor" stroke="none"/>',
  zoomIn: '<circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/><line x1="11" y1="8" x2="11" y2="14"/><line x1="8" y1="11" x2="14" y2="11"/>',
  cursorTool: '<path d="M4 3l7 17 2.2-7.2L20.5 10.5 4 3z"/>',
  circleTool: '<circle cx="12" cy="12" r="8"/>',
  squareTool: '<rect x="4" y="4" width="16" height="16" rx="1.5"/>',
  arrowTool: '<line x1="6" y1="18" x2="18" y2="6"/><polyline points="9 6 18 6 18 15"/>',
  lineTool: '<line x1="5" y1="19" x2="19" y2="5"/>',
  highlighterTool: '<path d="M6 20l2-5 9-9 4 4-9 9-5 2z"/><line x1="14" y1="8" x2="18" y2="12"/>',
  textTool: '<polyline points="5 5 5 3 19 3 19 5"/><line x1="12" y1="3" x2="12" y2="21"/><line x1="9" y1="21" x2="15" y2="21"/>',
  hashTool: '<line x1="5" y1="9" x2="19" y2="9"/><line x1="5" y1="15" x2="19" y2="15"/><line x1="9" y1="4" x2="7" y2="20"/><line x1="17" y1="4" x2="15" y2="20"/>',
  undoTool: '<path d="M9 14 4 9l5-5"/><path d="M4 9h11a5 5 0 0 1 0 10h-1"/>',
  redoTool: '<path d="M15 14l5-5-5-5"/><path d="M20 9H9a5 5 0 0 0 0 10h1"/>',
  compareTool: '<rect x="3" y="4" width="8" height="16" rx="1"/><rect x="13" y="4" width="8" height="16" rx="1"/>',
  fullscreenTool: '<path d="M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5"/>'
};

window.icon = function (name, size) {
  var s = size || 18;
  var body = window.ICONS[name] || window.ICONS.info;
  return '<svg width="' + s + '" height="' + s + '" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + body + '</svg>';
};
