import { createRoot } from 'react-dom/client';
import App from './App.jsx';
import './styles.css';

// PDF tooling is intentionally lazy: it is needed only after a report exists.
window.SidarPdf = {
  load: async () => {
    const [{ jsPDF }, { default: html2canvas }] = await Promise.all([
      import('jspdf'),
      import('html2canvas'),
    ]);
    return { jsPDF, html2canvas };
  },
};

createRoot(document.getElementById('root')).render(<App />);
