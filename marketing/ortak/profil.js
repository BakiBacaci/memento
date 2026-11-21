// Memento profil ekranı (uygulamadaki koyu temanın birebir düzeni). İki videoda ortak.
// profileScreen() bir .screen içine konacak HTML döner; sayılar id'lerle güncellenir:
//   #pf-fol (takipçi), #pf-karma, #pf-bar (karma çubuğu), #pf-lvl
window.profileScreen = function profileScreen(opts = {}) {
  const u = opts.user || 'deniz';
  const tiles = [
    ['#C9B6FF', '#2A1460', 'Bazı insanlar gider, sözleri kalır.'],
    ['#FF9F80', '#4A1406', 'Bugün de geçti.'],
    ['#D7F75B', '#24400A', 'Yavaş git ama durma.'],
    ['#9AD1FF', '#0A2A4A', 'Gece yazar, sabah siler.'],
  ];
  const bell = '<svg width="34" height="34" viewBox="0 0 24 24"><path d="M6 17V11a6 6 0 1 1 12 0v6l1.5 2h-15zM10 21h4" fill="none" stroke="#F5F3EE" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
  const menu = '<svg width="34" height="34" viewBox="0 0 24 24"><path d="M4 7h16M4 12h16M4 17h16" stroke="#F5F3EE" stroke-width="2" stroke-linecap="round"/></svg>';
  return `
  <div class="notch"></div>
  <div class="abs" style="left:44px; top:112px; font-weight:800; font-size:34px;">@${u}</div>
  <div class="abs" style="right:100px; top:108px;">${bell}<span id="pf-dot" style="position:absolute; right:-2px; top:0; width:14px; height:14px; border-radius:50%; background:#E5484D;"></span></div>
  <div class="abs" style="right:44px; top:108px;">${menu}</div>
  <div class="abs" style="left:40px; top:180px; width:124px; height:124px; border-radius:50%; background:#C9B6FF; padding:6px;">
    <div style="width:100%; height:100%; border-radius:50%; background:#2A1460; color:#C9B6FF; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:56px;">D</div></div>
  <div class="abs" style="left:186px; top:186px; font-weight:800; font-size:52px; letter-spacing:-1.5px;">Deniz</div>
  <div class="abs" style="left:186px; top:256px; font-size:24px; color:#A3A3A9; white-space:nowrap;"><b style="color:#F5F3EE">12</b> söz &nbsp; <b id="pf-fol" style="color:#F5F3EE">248</b> takipçi &nbsp; <b style="color:#F5F3EE">31</b> takip</div>
  <div class="abs" style="left:40px; top:330px; font-size:26px;">Gece yazar, sabah siler.</div>
  <div class="abs" style="left:40px; top:384px; width:528px; height:200px; border-radius:34px; background:#C9B6FF; color:#2A1460; padding:26px 30px;">
    <div style="font-weight:600; font-size:20px; opacity:.75;">Sabitlenen söz</div>
    <div style="margin-top:8px; font-weight:800; font-size:38px; line-height:1.02; letter-spacing:-1px;">Bazı insanlar gider, sözleri kalır.</div></div>
  <div class="abs" style="left:40px; top:604px; width:528px; height:122px; border-radius:30px; background:#D7F75B; color:#24400A; padding:20px 28px;">
    <div style="display:flex; align-items:baseline; gap:10px;"><span id="pf-karma" style="font-weight:800; font-size:42px; letter-spacing:-1px;">86</span><span style="font-weight:600; font-size:22px;">karma</span>
      <span id="pf-lvl" style="margin-left:auto; font-weight:600; font-size:20px;">Seviye 2</span></div>
    <div style="margin-top:12px; height:10px; border-radius:5px; background:rgba(36,64,10,.15);"><div id="pf-bar" style="height:100%; width:30%; border-radius:5px; background:#24400A;"></div></div></div>
  <div class="abs" style="left:40px; top:750px; width:528px; display:flex; justify-content:space-between; font-weight:600; font-size:24px; color:#A3A3A9;">
    <span style="color:#F5F3EE; border-bottom:4px solid #F5F3EE; padding-bottom:10px;">Sözler</span><span>Kaydedilenler</span><span>Beğendiklerim</span></div>
  ${tiles.map(([bg, ink, q], i) => `<div class="abs" style="left:${40 + (i % 2) * 272}px; top:${818 + Math.floor(i / 2) * 222}px; width:256px; height:206px; border-radius:28px; background:${bg}; color:${ink}; padding:22px; font-weight:800; font-size:28px; line-height:1.04; letter-spacing:-.6px;">${q}</div>`).join('')}
  `;
};
