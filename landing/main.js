/**
 * VECTOR NOVA // Interactive Landing Page & Simulator Suite
 * Features:
 * - 3-Tier Procedural Parallax Starfield Canvas
 * - Web Audio API Sci-Fi Synthesizer (Lasers, EMP Rumble, Upgrade Chimes)
 * - Interactive Touch Control Comparison (Relative Drag vs Occluded Direct)
 * - Interactive Firing Range with 4 Weapon Tiers & Live Drone Targets
 * - Interactive Hangar Tech Tree Simulator with LocalStorage Persistence
 * - 3D Perspective Card Tilt & Boss Phase Explorer
 */

(function () {
  'use strict';

  // ==========================================================================
  // 1. PROCEDURAL WEB AUDIO API SYNTHESIZER
  // ==========================================================================
  class AudioSynth {
    constructor() {
      this.ctx = null;
      this.muted = localStorage.getItem('vn_sfx_muted') === 'true';
    }

    init() {
      if (!this.ctx) {
        const AudioContext = window.AudioContext || window.webkitAudioContext;
        if (AudioContext) {
          this.ctx = new AudioContext();
        }
      }
      if (this.ctx && this.ctx.state === 'suspended') {
        this.ctx.resume();
      }
    }

    playLaser(tier = 1) {
      if (this.muted) return;
      this.init();
      if (!this.ctx) return;

      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      const now = this.ctx.currentTime;

      osc.type = tier >= 4 ? 'sawtooth' : 'triangle';
      const startFreq = 880 + tier * 160;
      osc.frequency.setValueAtTime(startFreq, now);
      osc.frequency.exponentialRampToValueAtTime(140, now + 0.12);

      gain.gain.setValueAtTime(0.12, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);

      osc.connect(gain);
      gain.connect(this.ctx.destination);

      osc.start(now);
      osc.stop(now + 0.13);
    }

    playEmp() {
      if (this.muted) return;
      this.init();
      if (!this.ctx) return;

      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(320, now);
      osc.frequency.exponentialRampToValueAtTime(35, now + 0.6);

      gain.gain.setValueAtTime(0.3, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);

      osc.connect(gain);
      gain.connect(this.ctx.destination);

      osc.start(now);
      osc.stop(now + 0.65);
    }

    playUpgrade() {
      if (this.muted) return;
      this.init();
      if (!this.ctx) return;

      const now = this.ctx.currentTime;
      [523.25, 659.25, 783.99, 1046.5].forEach((freq, i) => {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sine';
        osc.frequency.value = freq;
        gain.gain.setValueAtTime(0.08, now + i * 0.06);
        gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.06 + 0.15);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(now + i * 0.06);
        osc.stop(now + i * 0.06 + 0.16);
      });
    }

    playClick() {
      if (this.muted) return;
      this.init();
      if (!this.ctx) return;

      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(1200, now);
      osc.frequency.exponentialRampToValueAtTime(400, now + 0.04);
      gain.gain.setValueAtTime(0.06, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start(now);
      osc.stop(now + 0.05);
    }

    toggleMute() {
      this.muted = !this.muted;
      localStorage.setItem('vn_sfx_muted', this.muted);
      return !this.muted;
    }
  }

  const synth = new AudioSynth();

  // Setup Sound Toggle UI
  const sfxBtn = document.getElementById('sfx-toggle-btn');
  if (sfxBtn) {
    const sfxOnIcon = sfxBtn.querySelector('.sfx-on');
    const sfxOffIcon = sfxBtn.querySelector('.sfx-off');
    const sfxStatus = sfxBtn.querySelector('.sfx-status');

    function updateSfxUi(active) {
      if (active) {
        if (sfxOnIcon) sfxOnIcon.style.display = 'block';
        if (sfxOffIcon) sfxOffIcon.style.display = 'none';
        if (sfxStatus) sfxStatus.textContent = 'SFX: ON';
      } else {
        if (sfxOnIcon) sfxOnIcon.style.display = 'none';
        if (sfxOffIcon) sfxOffIcon.style.display = 'block';
        if (sfxStatus) sfxStatus.textContent = 'SFX: MUTED';
      }
    }

    updateSfxUi(!synth.muted);

    sfxBtn.addEventListener('click', () => {
      synth.init();
      const active = synth.toggleMute();
      updateSfxUi(active);
      if (active) synth.playClick();
    });
  }

  // ==========================================================================
  // 2. PARALLAX STARFIELD BACKGROUND
  // ==========================================================================
  (function initStarfield() {
    const canvas = document.getElementById('starfield');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');

    let width = (canvas.width = window.innerWidth);
    let height = (canvas.height = window.innerHeight);

    window.addEventListener('resize', () => {
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    });

    const stars = [];
    const count = 160;

    for (let i = 0; i < count; i++) {
      stars.push({
        x: Math.random() * width,
        y: Math.random() * height,
        speed: Math.random() * 2.8 + 0.6,
        radius: Math.random() * 1.5 + 0.5,
        alpha: Math.random() * 0.8 + 0.2,
        layer: Math.floor(Math.random() * 3),
      });
    }

    function render() {
      ctx.clearRect(0, 0, width, height);

      for (let i = 0; i < stars.length; i++) {
        const s = stars[i];
        s.x -= s.speed;
        if (s.x < 0) {
          s.x = width;
          s.y = Math.random() * height;
        }

        ctx.beginPath();
        if (s.layer === 2) {
          // Fast streak
          ctx.strokeStyle = `rgba(255, 255, 255, ${s.alpha})`;
          ctx.lineWidth = 1.4;
          ctx.moveTo(s.x, s.y);
          ctx.lineTo(s.x + 14, s.y);
          ctx.stroke();
        } else if (s.layer === 1) {
          // Mid cyan
          ctx.fillStyle = `rgba(0, 247, 255, ${s.alpha})`;
          ctx.arc(s.x, s.y, s.radius * 1.2, 0, Math.PI * 2);
          ctx.fill();
        } else {
          // Distant star
          ctx.fillStyle = `rgba(148, 163, 184, ${s.alpha * 0.6})`;
          ctx.arc(s.x, s.y, s.radius, 0, Math.PI * 2);
          ctx.fill();
        }
      }

      requestAnimationFrame(render);
    }
    render();
  })();

  // ==========================================================================
  // 3. INTERACTIVE TOUCH CONTROLS SIMULATOR (RELATIVE VS DIRECT)
  // ==========================================================================
  (function initControlsSimulator() {
    const canvas = document.getElementById('control-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');

    const tabRelative = document.getElementById('tab-relative');
    const tabDirect = document.getElementById('tab-direct');
    const explanation = document.getElementById('arena-explanation');

    let mode = 'relative'; // 'relative' or 'direct'
    let width = 0;
    let height = 0;

    const vanguardImg = new Image();
    vanguardImg.src = 'assets/sprites/player/vanguard-01-512.png';

    function resize() {
      const rect = canvas.getBoundingClientRect();
      width = canvas.width = rect.width;
      height = canvas.height = rect.height;
    }
    resize();
    window.addEventListener('resize', resize);

    let fingerX = 140;
    let fingerY = 220;
    let isDragging = false;
    let bankAngle = 0;
    let lastY = fingerY;

    // Hazards flying toward player
    const hazards = [];
    for (let i = 0; i < 4; i++) {
      hazards.push({
        x: 400 + i * 160,
        y: 80 + i * 65,
        speed: 2.2,
        radius: 10,
      });
    }

    function setMode(newMode) {
      mode = newMode;
      if (mode === 'relative') {
        tabRelative.classList.add('active');
        tabDirect.classList.remove('active');
        if (explanation) {
          explanation.innerHTML = `<strong>RELATIVE OFFSET ACTIVE</strong><span>Ship floats 70px above your thumb. Your vision is 100% unobstructed!</span>`;
        }
      } else {
        tabDirect.classList.add('active');
        tabRelative.classList.remove('active');
        if (explanation) {
          explanation.innerHTML = `<strong>DIRECT TOUCH ACTIVE (FATAL BLIND SPOT)</strong><span>Your thumb covers the ship and nearby hazards completely!</span>`;
        }
      }
      synth.playClick();
    }

    if (tabRelative) tabRelative.addEventListener('click', () => setMode('relative'));
    if (tabDirect) tabDirect.addEventListener('click', () => setMode('direct'));

    function onPointerMove(x, y) {
      const rect = canvas.getBoundingClientRect();
      fingerX = Math.max(30, Math.min(rect.width - 30, x - rect.left));
      fingerY = Math.max(40, Math.min(rect.height - 40, y - rect.top));

      // Calculate banking tilt
      const deltaY = fingerY - lastY;
      bankAngle = Math.max(-0.25, Math.min(0.25, deltaY * 0.05));
      lastY = fingerY;
    }

    canvas.addEventListener('mousemove', (e) => {
      onPointerMove(e.clientX, e.clientY);
    });

    canvas.addEventListener('touchmove', (e) => {
      if (e.touches.length > 0) {
        e.preventDefault();
        onPointerMove(e.touches[0].clientX, e.touches[0].clientY);
      }
    }, { passive: false });

    function renderSimulator() {
      ctx.clearRect(0, 0, width, height);

      // Subtle grid
      ctx.strokeStyle = 'rgba(0, 247, 255, 0.05)';
      ctx.lineWidth = 1;
      for (let x = 0; x < width; x += 30) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, height);
        ctx.stroke();
      }

      // Update hazards
      hazards.forEach((h) => {
        h.x -= h.speed;
        if (h.x < -20) {
          h.x = width + Math.random() * 60;
          h.y = Math.random() * (height - 60) + 30;
        }

        // Draw red hazard bullet
        ctx.beginPath();
        ctx.arc(h.x, h.y, h.radius, 0, Math.PI * 2);
        ctx.fillStyle = '#ff2a5f';
        ctx.shadowColor = '#ff2a5f';
        ctx.shadowBlur = 10;
        ctx.fill();
        ctx.shadowBlur = 0;
      });

      // Ship positioning based on mode
      const shipX = fingerX;
      const shipY = mode === 'relative' ? Math.max(30, fingerY - 70) : fingerY;

      // Draw dashed connection telemetry if in relative mode
      if (mode === 'relative') {
        ctx.save();
        ctx.strokeStyle = 'rgba(0, 247, 255, 0.35)';
        ctx.lineWidth = 1.5;
        ctx.setLineDash([4, 4]);
        ctx.beginPath();
        ctx.moveTo(fingerX, fingerY);
        ctx.lineTo(shipX, shipY);
        ctx.stroke();
        ctx.restore();
      }

      // Draw Ship
      ctx.save();
      ctx.translate(shipX, shipY);
      ctx.rotate(bankAngle);

      // Plasma thruster flame
      ctx.beginPath();
      ctx.moveTo(-12, 0);
      ctx.lineTo(-24, -5);
      ctx.lineTo(-32 - Math.random() * 8, 0);
      ctx.lineTo(-24, 5);
      ctx.closePath();
      ctx.fillStyle = '#00f7ff';
      ctx.shadowColor = '#00f7ff';
      ctx.shadowBlur = 15;
      ctx.fill();
      ctx.shadowBlur = 0;

      if (vanguardImg.complete && vanguardImg.naturalWidth > 0) {
        // Draw Vanguard-01 sprite scaled cleanly (pointing right)
        const shipW = 48;
        const shipH = 48;
        ctx.drawImage(vanguardImg, -shipW / 2, -shipH / 2, shipW, shipH);
      } else {
        // High-tech vector fallback
        ctx.beginPath();
        ctx.moveTo(20, 0);
        ctx.lineTo(-15, -12);
        ctx.lineTo(-8, 0);
        ctx.lineTo(-15, 12);
        ctx.closePath();
        ctx.fillStyle = '#00f7ff';
        ctx.shadowColor = '#00f7ff';
        ctx.shadowBlur = 12;
        ctx.fill();
        ctx.shadowBlur = 0;
      }

      ctx.restore();

      // Draw Virtual Finger/Thumb
      ctx.save();
      ctx.translate(fingerX, fingerY);

      if (mode === 'direct') {
        // Obtrusive thumb occlusion overlay (red warning aura)
        ctx.beginPath();
        ctx.arc(0, 0, 36, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(255, 42, 95, 0.55)';
        ctx.strokeStyle = '#ff2a5f';
        ctx.lineWidth = 2;
        ctx.fill();
        ctx.stroke();

        ctx.fillStyle = '#fff';
        ctx.font = '10px Orbitron';
        ctx.textAlign = 'center';
        ctx.fillText('BLIND SPOT', 0, 4);
      } else {
        // Ergonomic semi-transparent touch pad
        ctx.beginPath();
        ctx.arc(0, 0, 24, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(0, 247, 255, 0.2)';
        ctx.strokeStyle = 'rgba(0, 247, 255, 0.8)';
        ctx.lineWidth = 2;
        ctx.fill();
        ctx.stroke();

        ctx.beginPath();
        ctx.arc(0, 0, 6, 0, Math.PI * 2);
        ctx.fillStyle = '#00f7ff';
        ctx.fill();
      }
      ctx.restore();

      // Smooth bank recovery
      bankAngle *= 0.9;

      requestAnimationFrame(renderSimulator);
    }
    renderSimulator();
  })();

  // ==========================================================================
  // 4. INTERACTIVE FIRING RANGE & WEAPONS LAB
  // ==========================================================================
  (function initFiringRange() {
    const canvas = document.getElementById('firing-range-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');

    const tierBtns = document.querySelectorAll('.tier-card');
    const tierLabel = document.getElementById('range-tier-label');
    const empBtn = document.getElementById('btn-trigger-emp');

    const vanguardImg = new Image();
    vanguardImg.src = 'assets/sprites/player/vanguard-01-512.png';
    const scoutImg = new Image();
    scoutImg.src = 'assets/sprites/enemies/scout-512.png';

    let currentTier = 1;
    let width = 0;
    let height = 0;

    function resize() {
      const rect = canvas.getBoundingClientRect();
      width = canvas.width = rect.width;
      height = canvas.height = rect.height;
    }
    resize();
    window.addEventListener('resize', resize);

    // Drones & Projectiles
    const bullets = [];
    const drones = [];
    const particles = [];
    let isFiring = false;
    let fireCooldown = 0;
    let empWaveRadius = 0;
    let empActive = false;

    // Spawn initial target drones
    function spawnDrone() {
      if (drones.length >= 6) return;
      drones.push({
        x: width + 20,
        y: Math.random() * (height - 80) + 40,
        speed: Math.random() * 1.5 + 1.2,
        hp: 3,
        maxHp: 3,
        radius: 16,
      });
    }

    tierBtns.forEach((btn) => {
      btn.addEventListener('click', () => {
        tierBtns.forEach((b) => b.classList.remove('active'));
        btn.classList.add('active');
        currentTier = parseInt(btn.dataset.tier, 10);

        const names = [
          'TIER 1 PULSE LASER',
          'TIER 2 TWIN PLASMA',
          'TIER 3 SPREAD SALVO',
          'TIER 4 OVERCHARGED + HOMING',
        ];
        if (tierLabel) {
          tierLabel.textContent = `ACTIVE LOADOUT: ${names[currentTier - 1]}`;
        }
        synth.playUpgrade();
      });
    });

    // Fire weapon logic
    function fireProjectiles() {
      const originX = 60;
      const originY = height / 2;

      synth.playLaser(currentTier);

      if (currentTier === 1) {
        // Single forward laser
        bullets.push({ x: originX, y: originY, vx: 14, vy: 0, type: 'laser', radius: 4 });
      } else if (currentTier === 2) {
        // Twin parallel lasers
        bullets.push({ x: originX, y: originY - 10, vx: 14, vy: 0, type: 'laser', radius: 4 });
        bullets.push({ x: originX, y: originY + 10, vx: 14, vy: 0, type: 'laser', radius: 4 });
      } else if (currentTier === 3) {
        // 3-way spread
        bullets.push({ x: originX, y: originY, vx: 14, vy: 0, type: 'laser', radius: 4 });
        bullets.push({ x: originX, y: originY, vx: 13, vy: -3, type: 'laser', radius: 4 });
        bullets.push({ x: originX, y: originY, vx: 13, vy: 3, type: 'laser', radius: 4 });
      } else if (currentTier === 4) {
        // Overcharged beam + homing micro-missiles
        bullets.push({ x: originX, y: originY - 8, vx: 16, vy: 0, type: 'plasma', radius: 6 });
        bullets.push({ x: originX, y: originY + 8, vx: 16, vy: 0, type: 'plasma', radius: 6 });

        // Micro-missiles
        bullets.push({
          x: originX,
          y: originY,
          vx: 6,
          vy: -4,
          type: 'missile',
          radius: 5,
          angle: -0.4,
        });
        bullets.push({
          x: originX,
          y: originY,
          vx: 6,
          vy: 4,
          type: 'missile',
          radius: 5,
          angle: 0.4,
        });
      }
    }

    // Trigger EMP
    if (empBtn) {
      empBtn.addEventListener('click', () => {
        empActive = true;
        empWaveRadius = 10;
        synth.playEmp();

        // Vaporize all drones
        drones.forEach((d) => {
          createExplosion(d.x, d.y, 25);
        });
        drones.length = 0;
      });
    }

    function createExplosion(x, y, count = 12) {
      for (let i = 0; i < count; i++) {
        const angle = Math.random() * Math.PI * 2;
        const speed = Math.random() * 4 + 1;
        particles.push({
          x,
          y,
          vx: Math.cos(angle) * speed,
          vy: Math.sin(angle) * speed,
          life: 30,
          color: Math.random() > 0.4 ? '#00f7ff' : '#fbbf24',
        });
      }
    }

    // Pointer events for firing
    canvas.addEventListener('mousedown', () => (isFiring = true));
    window.addEventListener('mouseup', () => (isFiring = false));
    canvas.addEventListener('touchstart', (e) => {
      e.preventDefault();
      isFiring = true;
    }, { passive: false });
    window.addEventListener('touchend', () => (isFiring = false));

    // Range render loop
    let frame = 0;
    function renderRange() {
      ctx.clearRect(0, 0, width, height);
      frame++;

      // Drone spawner
      if (frame % 70 === 0) {
        spawnDrone();
      }

      // Handle continuous firing
      if (isFiring && fireCooldown <= 0) {
        fireProjectiles();
        fireCooldown = currentTier === 4 ? 8 : 10;
      }
      if (fireCooldown > 0) fireCooldown--;

      // Render Player Ship in Range (Vanguard-01)
      const shipX = 40;
      const shipY = height / 2;

      ctx.save();
      ctx.translate(shipX, shipY);

      // Thruster flame
      ctx.beginPath();
      ctx.moveTo(-16, 0);
      ctx.lineTo(-28, -6);
      ctx.lineTo(-36 - Math.random() * 8, 0);
      ctx.lineTo(-28, 6);
      ctx.closePath();
      ctx.fillStyle = '#00f7ff';
      ctx.shadowColor = '#00f7ff';
      ctx.shadowBlur = 14;
      ctx.fill();
      ctx.shadowBlur = 0;

      if (vanguardImg.complete && vanguardImg.naturalWidth > 0) {
        const shipW = 52;
        const shipH = 52;
        ctx.drawImage(vanguardImg, -shipW / 2, -shipH / 2, shipW, shipH);
      } else {
        ctx.beginPath();
        ctx.moveTo(20, 0);
        ctx.lineTo(-15, -12);
        ctx.lineTo(-6, 0);
        ctx.lineTo(-15, 12);
        ctx.closePath();
        ctx.fillStyle = '#00f7ff';
        ctx.shadowColor = '#00f7ff';
        ctx.shadowBlur = 14;
        ctx.fill();
        ctx.shadowBlur = 0;
      }
      ctx.restore();

      // Render & Update Bullets
      for (let i = bullets.length - 1; i >= 0; i--) {
        const b = bullets[i];

        if (b.type === 'missile') {
          // Homing logic towards closest drone
          let target = null;
          let minDist = 99999;
          drones.forEach((d) => {
            const dist = Math.hypot(d.x - b.x, d.y - b.y);
            if (dist < minDist) {
              minDist = dist;
              target = d;
            }
          });

          if (target) {
            const angleTo = Math.atan2(target.y - b.y, target.x - b.x);
            b.vx += Math.cos(angleTo) * 0.8;
            b.vy += Math.sin(angleTo) * 0.8;
            // Cap speed
            const speed = Math.hypot(b.vx, b.vy);
            if (speed > 13) {
              b.vx = (b.vx / speed) * 13;
              b.vy = (b.vy / speed) * 13;
            }
          }
        }

        b.x += b.vx;
        b.y += b.vy;

        // Draw bullet
        ctx.beginPath();
        if (b.type === 'plasma') {
          ctx.arc(b.x, b.y, b.radius, 0, Math.PI * 2);
          ctx.fillStyle = '#00f7ff';
          ctx.shadowColor = '#00f7ff';
          ctx.shadowBlur = 15;
          ctx.fill();
        } else if (b.type === 'missile') {
          ctx.arc(b.x, b.y, b.radius, 0, Math.PI * 2);
          ctx.fillStyle = '#fbbf24';
          ctx.shadowColor = '#fbbf24';
          ctx.shadowBlur = 10;
          ctx.fill();
        } else {
          // Laser beam
          ctx.strokeStyle = '#00f7ff';
          ctx.lineWidth = 3;
          ctx.moveTo(b.x - 12, b.y);
          ctx.lineTo(b.x, b.y);
          ctx.stroke();
        }
        ctx.shadowBlur = 0;

        // Collision with drones
        let hit = false;
        for (let j = drones.length - 1; j >= 0; j--) {
          const d = drones[j];
          if (Math.hypot(d.x - b.x, d.y - b.y) < d.radius + b.radius) {
            d.hp--;
            createExplosion(b.x, b.y, 6);
            hit = true;
            if (d.hp <= 0) {
              createExplosion(d.x, d.y, 16);
              drones.splice(j, 1);
            }
            break;
          }
        }

        if (hit || b.x > width + 30 || b.y < 0 || b.y > height) {
          bullets.splice(i, 1);
        }
      }

      // Render & Update Enemy Scout Ships
      for (let i = drones.length - 1; i >= 0; i--) {
        const d = drones[i];
        d.x -= d.speed;

        ctx.save();
        ctx.translate(d.x, d.y);

        if (scoutImg.complete && scoutImg.naturalWidth > 0) {
          // Flip horizontally so the Scout ship faces left (toward player)
          ctx.save();
          ctx.scale(-1, 1);
          const scoutW = 44;
          const scoutH = 44;
          ctx.drawImage(scoutImg, -scoutW / 2, -scoutH / 2, scoutW, scoutH);
          ctx.restore();
        } else {
          // Sleek vector Scout fallback
          ctx.beginPath();
          ctx.moveTo(-16, 0);
          ctx.lineTo(12, -10);
          ctx.lineTo(6, 0);
          ctx.lineTo(12, 10);
          ctx.closePath();
          ctx.fillStyle = '#ff2a5f';
          ctx.shadowColor = '#ff2a5f';
          ctx.shadowBlur = 10;
          ctx.fill();
          ctx.shadowBlur = 0;
        }

        // Mini HP Bar above Scout ship
        if (d.hp < d.maxHp) {
          const barW = 24;
          const hpRatio = d.hp / d.maxHp;
          ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
          ctx.fillRect(-barW / 2, -22, barW, 3);
          ctx.fillStyle = '#ff2a5f';
          ctx.fillRect(-barW / 2, -22, barW * hpRatio, 3);
        }

        ctx.restore();

        if (d.x < -40) drones.splice(i, 1);
      }

      // Render Particles
      for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.life--;

        ctx.beginPath();
        ctx.arc(p.x, p.y, 2, 0, Math.PI * 2);
        ctx.fillStyle = p.color;
        ctx.fill();

        if (p.life <= 0) particles.splice(i, 1);
      }

      // Render EMP Shockwave Expansion
      if (empActive) {
        empWaveRadius += 18;
        ctx.save();
        ctx.beginPath();
        ctx.arc(40, height / 2, empWaveRadius, 0, Math.PI * 2);
        ctx.strokeStyle = `rgba(0, 247, 255, ${Math.max(0, 1 - empWaveRadius / width)})`;
        ctx.lineWidth = 6;
        ctx.shadowColor = '#00f7ff';
        ctx.shadowBlur = 25;
        ctx.stroke();
        ctx.restore();

        if (empWaveRadius > width * 1.2) {
          empActive = false;
        }
      }

      requestAnimationFrame(renderRange);
    }
    renderRange();
  })();

  // ==========================================================================
  // 5. INTERACTIVE HANGAR TECH TREE SIMULATOR
  // ==========================================================================
  (function initHangarSim() {
    const scrapValEl = document.getElementById('sim-scrap-val');
    const btnAddScrap = document.getElementById('btn-add-scrap');
    const btnResetTech = document.getElementById('btn-reset-tech');

    // Upgrade elements
    const stats = {
      hull: {
        lvl: 1,
        maxLvl: 5,
        baseCost: 40,
        costMul: 1.5,
        calcText: (lvl) => `CURRENT: ${100 + (lvl - 1) * 15} HP`,
        badgeEl: document.getElementById('lvl-badge-hull'),
        meterEl: document.getElementById('meter-hull'),
        calcEl: document.getElementById('stat-calc-hull'),
        costEl: document.getElementById('cost-hull'),
        btnEl: document.getElementById('btn-buy-hull'),
      },
      firerate: {
        lvl: 1,
        maxLvl: 5,
        baseCost: 50,
        costMul: 1.5,
        calcText: (lvl) => `CURRENT: ${(5.5 * (1 + (lvl - 1) * 0.07)).toFixed(1)} SHOTS/SEC`,
        badgeEl: document.getElementById('lvl-badge-firerate'),
        meterEl: document.getElementById('meter-firerate'),
        calcEl: document.getElementById('stat-calc-firerate'),
        costEl: document.getElementById('cost-firerate'),
        btnEl: document.getElementById('btn-buy-firerate'),
      },
      magnet: {
        lvl: 1,
        maxLvl: 5,
        baseCost: 35,
        costMul: 1.45,
        calcText: (lvl) => `CURRENT: ${160 + (lvl - 1) * 35} PX RADIUS`,
        badgeEl: document.getElementById('lvl-badge-magnet'),
        meterEl: document.getElementById('meter-magnet'),
        calcEl: document.getElementById('stat-calc-magnet'),
        costEl: document.getElementById('cost-magnet'),
        btnEl: document.getElementById('btn-buy-magnet'),
      },
    };

    let scrap = parseInt(localStorage.getItem('vn_sim_scrap') || '250', 10);

    // Load saved levels
    Object.keys(stats).forEach((k) => {
      const saved = localStorage.getItem(`vn_sim_lvl_${k}`);
      if (saved) stats[k].lvl = parseInt(saved, 10);
    });

    function getCost(stat) {
      return Math.round(stat.baseCost * Math.pow(stat.costMul, stat.lvl - 1));
    }

    function updateUi() {
      if (scrapValEl) scrapValEl.textContent = scrap;
      localStorage.setItem('vn_sim_scrap', scrap);

      Object.keys(stats).forEach((k) => {
        const s = stats[k];
        const cost = getCost(s);
        localStorage.setItem(`vn_sim_lvl_${k}`, s.lvl);

        if (s.badgeEl) s.badgeEl.textContent = s.lvl >= s.maxLvl ? 'MAX LEVEL' : `LVL ${s.lvl} / ${s.maxLvl}`;
        if (s.meterEl) s.meterEl.style.width = `${(s.lvl / s.maxLvl) * 100}%`;
        if (s.calcEl) s.calcEl.textContent = s.calcText(s.lvl);

        if (s.btnEl) {
          if (s.lvl >= s.maxLvl) {
            s.btnEl.disabled = true;
            s.btnEl.textContent = 'MAXED';
          } else {
            s.btnEl.disabled = scrap < cost;
            s.costEl.textContent = cost;
          }
        }
      });
    }

    updateUi();

    // Buy Upgrade Buttons
    Object.keys(stats).forEach((k) => {
      const s = stats[k];
      if (s.btnEl) {
        s.btnEl.addEventListener('click', () => {
          const cost = getCost(s);
          if (scrap >= cost && s.lvl < s.maxLvl) {
            scrap -= cost;
            s.lvl++;
            synth.playUpgrade();
            updateUi();
          }
        });
      }
    });

    // Add Scrap
    if (btnAddScrap) {
      btnAddScrap.addEventListener('click', () => {
        scrap += 100;
        synth.playClick();
        updateUi();
      });
    }

    // Reset Tech
    if (btnResetTech) {
      btnResetTech.addEventListener('click', () => {
        scrap = 250;
        Object.keys(stats).forEach((k) => (stats[k].lvl = 1));
        synth.playClick();
        updateUi();
      });
    }

    // Boosters Toggle
    const boosterCards = document.querySelectorAll('.booster-sim-card');
    boosterCards.forEach((b) => {
      b.addEventListener('click', () => {
        b.classList.toggle('active');
        const check = b.querySelector('.booster-check');
        if (check) {
          check.textContent = b.classList.contains('active') ? '●' : '○';
        }
        synth.playClick();
      });
    });
  })();

  // ==========================================================================
  // 6. BOSS PHASES ACCORDION EXPLORER
  // ==========================================================================
  (function initBossExplorer() {
    const phaseCards = document.querySelectorAll('.boss-phase-card');
    phaseCards.forEach((card) => {
      card.addEventListener('click', () => {
        phaseCards.forEach((c) => c.classList.remove('active'));
        card.classList.add('active');
        synth.playClick();
      });
    });
  })();

  // ==========================================================================
  // 7. 3D PERSPECTIVE CARD TILT ON HERO KEY ART
  // ==========================================================================
  (function initCardTilt() {
    const card = document.getElementById('hero-card');
    if (!card) return;

    card.addEventListener('mousemove', (e) => {
      const rect = card.getBoundingClientRect();
      const x = e.clientX - rect.left - rect.width / 2;
      const y = e.clientY - rect.top - rect.height / 2;
      const rotateX = (-y / rect.height) * 16;
      const rotateY = (x / rect.width) * 16;

      card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale(1.02)`;
    });

    card.addEventListener('mouseleave', () => {
      card.style.transform = 'perspective(1000px) rotateX(0deg) rotateY(0deg) scale(1)';
    });
  })();

  // ==========================================================================
  // 8. MOBILE HAMBURGER MENU TOGGLE
  // ==========================================================================
  (function initMobileMenu() {
    const toggle = document.getElementById('menu-toggle');
    const nav = document.getElementById('main-nav');
    if (!toggle || !nav) return;

    toggle.addEventListener('click', () => {
      nav.classList.toggle('mobile-open');
    });

    document.querySelectorAll('.nav-link').forEach((link) => {
      link.addEventListener('click', () => {
        nav.classList.remove('mobile-open');
      });
    });
  })();

})();
