import puppeteer from 'puppeteer';

(async () => {
  console.log('Starting puppeteer...');
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  console.log('Navigating to http://127.0.0.1:4173...');
  try {
    await page.goto('http://127.0.0.1:4173', { waitUntil: 'networkidle0', timeout: 30000 });
  } catch (e) {
    console.error("First attempt failed, trying localhost...", e);
    await page.goto('http://localhost:4173', { waitUntil: 'networkidle0', timeout: 30000 });
  }
  
  const desktopPath = process.env.USERPROFILE + '\\Desktop\\Prototipo.pdf';
  console.log('Generating PDF at ' + desktopPath);
  
  await page.pdf({
    path: desktopPath,
    format: 'A4',
    printBackground: true,
    landscape: true // The prototype looks like a dashboard, so landscape might be better, let's just make it landscape or standard
  });

  await browser.close();
  console.log('Done!');
})();
