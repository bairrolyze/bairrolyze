// HomeScope – Radar Chart (DNA Widget)
// Canvas-based heptagonal radar chart mirroring dna_widget.dart

import { categoryColor, categoryEmoji, CATEGORIES } from '../utils.js';

export function renderRadarChart(canvas, categories) {
  const ctx = canvas.getContext('2d');
  const W = canvas.width;
  const H = canvas.height;
  const cx = W / 2;
  const cy = H / 2;
  const R = Math.min(W, H) * 0.38;
  const N = CATEGORIES.length;

  ctx.clearRect(0, 0, W, H);

  // ── Grid rings ────────────────────────────────────────────────────────────────
  [0.25, 0.5, 0.75, 1.0].forEach(factor => {
    ctx.beginPath();
    CATEGORIES.forEach((_, i) => {
      const angle = (Math.PI * 2 * i) / N - Math.PI / 2;
      const x = cx + Math.cos(angle) * R * factor;
      const y = cy + Math.sin(angle) * R * factor;
      i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
    });
    ctx.closePath();
    ctx.strokeStyle = 'rgba(255,255,255,0.06)';
    ctx.lineWidth = 1;
    ctx.stroke();
  });

  // ── Spokes ────────────────────────────────────────────────────────────────────
  CATEGORIES.forEach((_, i) => {
    const angle = (Math.PI * 2 * i) / N - Math.PI / 2;
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(cx + Math.cos(angle) * R, cy + Math.sin(angle) * R);
    ctx.strokeStyle = 'rgba(255,255,255,0.08)';
    ctx.lineWidth = 1;
    ctx.stroke();
  });

  // ── Data polygon ──────────────────────────────────────────────────────────────
  ctx.beginPath();
  CATEGORIES.forEach((catId, i) => {
    const cat = categories?.[catId];
    const val = (cat?.score ?? 0) / 100;
    const angle = (Math.PI * 2 * i) / N - Math.PI / 2;
    const x = cx + Math.cos(angle) * R * val;
    const y = cy + Math.sin(angle) * R * val;
    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
  });
  ctx.closePath();

  // Gradient fill
  const grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, R);
  grad.addColorStop(0, 'rgba(108, 99, 255, 0.4)');
  grad.addColorStop(1, 'rgba(108, 99, 255, 0.05)');
  ctx.fillStyle = grad;
  ctx.fill();
  ctx.strokeStyle = 'rgba(108,99,255,0.8)';
  ctx.lineWidth = 2;
  ctx.stroke();

  // ── Dots + labels ─────────────────────────────────────────────────────────────
  const LABEL_OFFSET = R + 22;
  CATEGORIES.forEach((catId, i) => {
    const cat = categories?.[catId];
    const val = (cat?.score ?? 0) / 100;
    const angle = (Math.PI * 2 * i) / N - Math.PI / 2;
    const dx = cx + Math.cos(angle) * R * val;
    const dy = cy + Math.sin(angle) * R * val;

    // Dot
    ctx.beginPath();
    ctx.arc(dx, dy, 4, 0, Math.PI * 2);
    ctx.fillStyle = categoryColor(catId);
    ctx.fill();

    // Label
    const lx = cx + Math.cos(angle) * LABEL_OFFSET;
    const ly = cy + Math.sin(angle) * LABEL_OFFSET;
    ctx.font = '11px Inter, sans-serif';
    ctx.fillStyle = 'rgba(255,255,255,0.7)';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(categoryEmoji(catId), lx, ly - 7);
    ctx.font = '9px Inter, sans-serif';
    ctx.fillStyle = 'rgba(255,255,255,0.45)';
    ctx.fillText(Math.round((cat?.score ?? 0)), lx, ly + 7);
  });
}
