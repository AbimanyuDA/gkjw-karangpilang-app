// Terapkan tema tersimpan sebelum render pertama agar tidak berkedip.
try {
  var t = localStorage.getItem('gkjw-admin-theme');
  if (t === 'light' || t === 'dark') document.documentElement.dataset.theme = t;
} catch (e) {}
