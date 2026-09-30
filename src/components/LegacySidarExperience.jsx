import { useEffect, useState } from 'react';

const legacyScripts = [
  { src: '/js/config.js?v=20260927' },
  { src: '/js/translations.js?v=20260927' },
  { src: 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2' },
  { src: '/js/supabase.js?v=20260927' },
  { src: '/js/firebase-ai.js?v=20260927', type: 'module' },
  { src: '/js/app.js?v=20260927' },
];

function loadLegacyScript({ src, type }) {
  return new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = src;
    script.async = false;
    if (type) script.type = type;
    script.dataset.sidarLegacy = 'true';
    script.onload = resolve;
    script.onerror = () => reject(new Error(`Unable to load required application resource: ${src}`));
    document.body.appendChild(script);
  });
}

async function installLegacyScripts() {
  for (const script of legacyScripts) {
    await loadLegacyScript(script);
  }
}

function installLegacyHelpers() {
  window.switchParam = (button, id) => {
    const page = document.getElementById('scan');
    if (!page) return;
    page.querySelectorAll('.ptab').forEach((tab) => tab.classList.remove('on'));
    button.classList.add('on');
    page.querySelectorAll('.param-panel').forEach((panel) => panel.classList.remove('on'));
    document.getElementById(`pp-${id}`)?.classList.add('on');
  };
}

function isSidarBooted() {
  return window.__sidarLegacyBooted === true;
}

function markSidarBooted() {
  window.__sidarLegacyBooted = true;
}

export default function LegacySidarExperience() {
  const [markup, setMarkup] = useState('');

  useEffect(() => {
    let active = true;
    const addedStyles = [];
    // The visible interface is injected before its legacy scripts finish
    // loading.  Keep the first CTA responsive instead of making visitors tap
    // it repeatedly while the app is warming up.
    const acknowledgeEarlyScanIntent = (event) => {
      const link = event.target.closest?.('a[href="#scan"]');
      if (!link || window.__sidarLegacyReady) return;
      document.documentElement.classList.add('sidar-opening-scan');
      link.setAttribute('aria-busy', 'true');
      window.setTimeout(() => {
        link.removeAttribute('aria-busy');
        document.documentElement.classList.remove('sidar-opening-scan');
      }, 3500);
    };
    document.addEventListener('click', acknowledgeEarlyScanIntent, true);
    fetch('/legacy.html?v=20260927', { cache: 'no-store' })
      .then((response) => {
        if (!response.ok) throw new Error('Unable to load the SIDAR interface.');
        return response.text();
      })
      .then((html) => {
        if (!active) return;
        const parsed = new DOMParser().parseFromString(html, 'text/html');
        parsed.head.querySelectorAll('style').forEach((style) => {
          const node = document.createElement('style');
          node.dataset.sidarLegacy = 'true';
          node.textContent = style.textContent;
          document.head.appendChild(node);
          addedStyles.push(node);
        });
        installLegacyHelpers();
        setMarkup(parsed.body.innerHTML.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, ''));
      })
      .catch((error) => active && setMarkup(`<main class="sec"><div class="wrap"><p>${error.message}</p></div></main>`));
    return () => {
      active = false;
      document.removeEventListener('click', acknowledgeEarlyScanIntent, true);
      addedStyles.forEach((node) => node.remove());
    };
  }, []);

  useEffect(() => {
    if (!markup || isSidarBooted()) return;
    markSidarBooted();
    installLegacyScripts().then(() => {
      document.documentElement.classList.remove('sidar-opening-scan');
    }).catch((error) => {
      console.error(error);
      setMarkup(`<main class="sec"><div class="wrap"><p>${error.message}</p></div></main>`);
    });
  }, [markup]);

  return <div dangerouslySetInnerHTML={{ __html: markup }} />;
}
