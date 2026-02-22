const http = require('http');
const https = require('https');

const port = 3000;

// locations
const locations = [
  { name: "大倉山 (Okurayama)", lat: 35.53, lon: 139.63 },
  { name: "東京 (Tokyo)", lat: 35.68, lon: 139.76 }
];

async function fetchWeather(lat, lon) {
  return new Promise((resolve, reject) => {
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,precipitation_probability_max&timezone=Asia%2FTokyo&past_days=1&forecast_days=3`;
    
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

function getWeatherIcon(code) {
  const icons = {
    0: '☀️', // Clear sky
    1: '🌤️', 2: '⛅', 3: '☁️', // Cloudy
    45: '🌫️', 48: '🌫️', // Fog
    51: '🌦️', 53: '🌦️', 55: '🌧️', // Drizzle
    61: '🌧️', 63: '🌧️', 65: '🌧️', // Rain
    71: '🌨️', 73: '🌨️', 75: '❄️', // Snow
    95: '⛈️' // Thunderstorm
  };
  return icons[code] || '☁️';
}

function getAdvice(maxTempDiff, minTempDiff, apparentMaxToday, rainProbToday) {
  let diffText = "";

  if (maxTempDiff <= -5) diffText = "昨日と比べて大きく気温が下がります📉。";
  else if (maxTempDiff <= -2) diffText = "昨日より少し涼しくなります。";
  else if (maxTempDiff >= 5) diffText = "昨日から一気に気温が上がります📈。";
  else if (maxTempDiff >= 2) diffText = "昨日より少し暖かくなります。";
  else diffText = "昨日とほぼ同じ気温です。";

  let tempText = "";
  if (apparentMaxToday >= 30) tempText = "厳しい暑さです🥵 薄着・半袖で十分！こまめな水分補給と熱中症対策を。";
  else if (apparentMaxToday >= 25) tempText = "汗ばむ暑さです☀️ 日中は半袖や薄手のシャツがおすすめです。";
  else if (apparentMaxToday >= 18) tempText = "過ごしやすい気候です🌱 長袖シャツや薄手のカーディガンで快適に過ごせます。";
  else if (apparentMaxToday >= 12) tempText = "少し肌寒く感じます🧥 セーターやジャケットなど羽織るものを持参しましょう。";
  else if (apparentMaxToday >= 6) tempText = "寒さを感じる気温です🧣 冬用コートなど暖かめの服装で防寒してください。";
  else tempText = "厳しい寒さです🥶 ダウンジャケットやマフラーなどで万全な防寒対策を！";

  let rainText = "";
  if (rainProbToday >= 50) rainText = " ☔高い確率(" + rainProbToday + "%)で雨が降るため傘を忘れずに！";
  else if (rainProbToday >= 20) rainText = " 🌂にわか雨の可能性(" + rainProbToday + "%)があるので折りたたみ傘があると安心です。";

  return diffText + " " + tempText + rainText;
}

const server = http.createServer(async (req, res) => {
  if (req.url.startsWith('/api/weather')) {
    const urlParams = new URLSearchParams(req.url.split('?')[1]);
    const locIdx = parseInt(urlParams.get('loc')) || 0;
    const loc = locations[locIdx];
    
    try {
      const weatherData = await fetchWeather(loc.lat, loc.lon);
      const daily = weatherData.daily;
      
      const yesterday = {
        date: daily.time[0],
        maxTemp: daily.temperature_2m_max[0],
        minTemp: daily.temperature_2m_min[0],
        maxApp: daily.apparent_temperature_max[0],
        minApp: daily.apparent_temperature_min[0],
        rainPrep: daily.precipitation_probability_max[0],
        icon: getWeatherIcon(daily.weather_code[0])
      };
      
      const today = {
        date: daily.time[1],
        maxTemp: daily.temperature_2m_max[1],
        minTemp: daily.temperature_2m_min[1],
        maxApp: daily.apparent_temperature_max[1],
        minApp: daily.apparent_temperature_min[1],
        rainPrep: daily.precipitation_probability_max[1],
        icon: getWeatherIcon(daily.weather_code[1])
      };
      
      const tomorrow = {
        date: daily.time[2],
        maxTemp: daily.temperature_2m_max[2],
        minTemp: daily.temperature_2m_min[2],
        maxApp: daily.apparent_temperature_max[2],
        minApp: daily.apparent_temperature_min[2],
        rainPrep: daily.precipitation_probability_max[2],
        icon: getWeatherIcon(daily.weather_code[2])
      };
      
      const diffYesterday = {
        maxTempDiff: +(today.maxTemp - yesterday.maxTemp).toFixed(1),
        minTempDiff: +(today.minTemp - yesterday.minTemp).toFixed(1),
        maxAppDiff: +(today.maxApp - yesterday.maxApp).toFixed(1),
        minAppDiff: +(today.minApp - yesterday.minApp).toFixed(1)
      };

      const diffTomorrow = {
        maxTempDiff: +(tomorrow.maxTemp - today.maxTemp).toFixed(1),
        minTempDiff: +(tomorrow.minTemp - today.minTemp).toFixed(1),
        maxAppDiff: +(tomorrow.maxApp - today.maxApp).toFixed(1),
        minAppDiff: +(tomorrow.minApp - today.minApp).toFixed(1)
      };

      const advice = getAdvice(diffYesterday.maxTempDiff, diffYesterday.minTempDiff, today.maxApp, today.rainPrep);
      
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ location: loc.name, yesterday, today, tomorrow, diffYesterday, diffTomorrow, advice }));
    } catch (e) {
      res.writeHead(500);
      res.end(JSON.stringify({ error: e.message }));
    }
    return;
  }
  
  // Serve HTML
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.end(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Weather Diff Today</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          background: linear-gradient(135deg, #112d4e 0%, #3f72af 100%);
          color: white;
          margin: 0;
          min-height: 100vh;
          display: flex;
          flex-direction: column;
          align-items: center;
          padding: 30px 10px;
        }
        .app-container {
          background: rgba(255, 255, 255, 0.08);
          backdrop-filter: blur(20px);
          border-radius: 24px;
          padding: 25px;
          width: 100%;
          max-width: 500px;
          box-shadow: 0 15px 50px rgba(0, 0, 0, 0.4);
          border: 1px solid rgba(255, 255, 255, 0.15);
        }
        h2 { text-align: center; margin-top:0; font-size: 1.8rem; letter-spacing: 1px; }
        
        select {
          width: 100%;
          padding: 16px;
          border-radius: 12px;
          border: none;
          background: rgba(255,255,255,0.9);
          font-size: 1.2rem;
          font-weight: bold;
          margin-bottom: 25px;
          outline: none;
          color: #112d4e;
          cursor: pointer;
        }
        
        .advice-card {
          background: rgba(255, 255, 255, 0.95);
          color: #112d4e;
          border-radius: 16px;
          padding: 15px 20px;
          border-left: 6px solid #f9a826;
          margin-bottom: 25px;
        }
        .advice-label {
          font-size: 1rem;
          font-weight: bold;
          color: #f9a826;
          text-transform: uppercase;
          letter-spacing: 1px;
          margin-bottom: 5px;
        }
        .advice-card p {
          margin: 0;
          font-size: 1.1rem;
          line-height: 1.5;
          font-weight: 500;
        }
        
        .table-card {
          background: rgba(0, 0, 0, 0.2);
          border-radius: 20px;
          padding: 20px;
          margin-bottom: 20px;
        }
        
        table {
          width: 100%;
          border-collapse: collapse;
          text-align: center;
        }
        
        th, td {
          padding: 12px 5px;
          border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        th {
          font-size: 1rem;
          opacity: 0.8;
          font-weight: 500;
        }
        
        .row-icon { font-size: 2.2rem; }
        
        .temp-val {
          font-size: 1.6rem;
          font-weight: bold;
          display: block;
        }
        .temp-label {
          font-size: 0.8rem;
          opacity: 0.7;
          display: block;
        }
        .temp-diff {
          font-size: 0.9rem;
          margin-top: 2px;
          display: block;
          opacity: 0.9;
        }
        
        .positive { color: #ff8b94; }
        .negative { color: #80c6ff; }
        .rain-color { color: #90e0ef; font-weight: bold;}
        
        .highlight-today {
          background: rgba(255,255,255,0.1);
          border-radius: 12px;
        }
        
        #loading { text-align: center; font-size: 1.2rem; display: none; margin: 40px 0; }
      </style>
    </head>
    <body>
      <div class="app-container">
        <h2>Weather Diff Today</h2>
        
        <select id="locationSelect" onchange="fetchData()">
          <option value="0">大倉山 (Okurayama)</option>
          <option value="1">東京 (Tokyo)</option>
        </select>
        
        <div id="loading">Loading Data...</div>
        
        <div id="content" style="display: none;">
          
          <div class="advice-card">
            <div class="advice-label">アドバイス</div>
            <p id="adviceDetail">--</p>
          </div>
          
          <div class="table-card">
            <table>
              <thead>
                <tr>
                  <th></th>
                  <th>昨日</th>
                  <th>今日</th>
                  <th>明日</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><span class="temp-label">天気</span></td>
                  <td><span class="row-icon" id="icon1">☁️</span></td>
                  <td class="highlight-today"><span class="row-icon" id="icon2">☁️</span></td>
                  <td><span class="row-icon" id="icon3">☁️</span></td>
                </tr>
                <tr>
                  <td><span class="temp-label">最高<br>気温</span></td>
                  <td><span class="temp-val max-color" id="max1">--°</span></td>
                  <td class="highlight-today">
                    <span class="temp-val max-color" id="max2">--°</span>
                    <span class="temp-diff" id="maxDiff1">(--)</span>
                  </td>
                  <td>
                    <span class="temp-val max-color" id="max3">--°</span>
                    <span class="temp-diff" id="maxDiff2">(--)</span>
                  </td>
                </tr>
                <tr>
                  <td><span class="temp-label">最低<br>気温</span></td>
                  <td><span class="temp-val min-color" id="min1">--°</span></td>
                  <td class="highlight-today">
                    <span class="temp-val min-color" id="min2">--°</span>
                    <span class="temp-diff" id="minDiff1">(--)</span>
                  </td>
                  <td>
                    <span class="temp-val min-color" id="min3">--°</span>
                    <span class="temp-diff" id="minDiff2">(--)</span>
                  </td>
                </tr>
                <tr>
                  <td><span class="temp-label">降水<br>確率</span></td>
                  <td><span class="rain-color" id="rain1">--%</span></td>
                  <td class="highlight-today"><span class="rain-color" id="rain2">--%</span></td>
                  <td><span class="rain-color" id="rain3">--%</span></td>
                </tr>
              </tbody>
            </table>
          </div>
          
          <div class="table-card">
            <h3 style="margin-top:0; font-size:1.1rem; text-align:center; opacity:0.9;">体感温度</h3>
            <table>
              <thead>
                <tr>
                  <th></th>
                  <th>昨日</th>
                  <th>今日</th>
                  <th>明日</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><span class="temp-label">体感<br>最高</span></td>
                  <td><span class="temp-val max-color" id="appMax1" style="font-size:1.3rem;">--°</span></td>
                  <td class="highlight-today">
                    <span class="temp-val max-color" id="appMax2" style="font-size:1.3rem;">--°</span>
                    <span class="temp-diff" id="appMaxDiff1">(--)</span>
                  </td>
                  <td>
                    <span class="temp-val max-color" id="appMax3" style="font-size:1.3rem;">--°</span>
                    <span class="temp-diff" id="appMaxDiff2">(--)</span>
                  </td>
                </tr>
                <tr>
                  <td><span class="temp-label">体感<br>最低</span></td>
                  <td><span class="temp-val min-color" id="appMin1" style="font-size:1.3rem;">--°</span></td>
                  <td class="highlight-today">
                    <span class="temp-val min-color" id="appMin2" style="font-size:1.3rem;">--°</span>
                    <span class="temp-diff" id="appMinDiff1">(--)</span>
                  </td>
                  <td>
                    <span class="temp-val min-color" id="appMin3" style="font-size:1.3rem;">--°</span>
                    <span class="temp-diff" id="appMinDiff2">(--)</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

        </div>
      </div>
      
      <script>
        function formatDiff(val) {
          const sign = val > 0 ? '+' : '';
          const className = val > 0 ? 'positive' : val < 0 ? 'negative' : '';
          return \`(<span class="\${className}">\${sign}\${val}°</span>)\`;
        }
        
        async function fetchData() {
          const loc = document.getElementById('locationSelect').value;
          document.getElementById('loading').style.display = 'block';
          document.getElementById('content').style.display = 'none';
          
          try {
            const res = await fetch(\`/api/weather?loc=\${loc}\`);
            if(!res.ok) throw new Error("API Request Failed");
            const data = await res.json();
            
            // Advice
            document.getElementById('adviceDetail').innerText = data.advice;
            
            // Diffs Today (vs Yesterday)
            document.getElementById('maxDiff1').innerHTML = formatDiff(data.diffYesterday.maxTempDiff);
            document.getElementById('minDiff1').innerHTML = formatDiff(data.diffYesterday.minTempDiff);
            document.getElementById('appMaxDiff1').innerHTML = formatDiff(data.diffYesterday.maxAppDiff);
            document.getElementById('appMinDiff1').innerHTML = formatDiff(data.diffYesterday.minAppDiff);
            
            // Diffs Tomorrow (vs Today)
            document.getElementById('maxDiff2').innerHTML = formatDiff(data.diffTomorrow.maxTempDiff);
            document.getElementById('minDiff2').innerHTML = formatDiff(data.diffTomorrow.minTempDiff);
            document.getElementById('appMaxDiff2').innerHTML = formatDiff(data.diffTomorrow.maxAppDiff);
            document.getElementById('appMinDiff2').innerHTML = formatDiff(data.diffTomorrow.minAppDiff);
            
            // Yesterday
            document.getElementById('icon1').innerText = data.yesterday.icon;
            document.getElementById('max1').innerText = data.yesterday.maxTemp + '°';
            document.getElementById('min1').innerText = data.yesterday.minTemp + '°';
            document.getElementById('rain1').innerText = data.yesterday.rainPrep + '%';
            document.getElementById('appMax1').innerText = data.yesterday.maxApp + '°';
            document.getElementById('appMin1').innerText = data.yesterday.minApp + '°';
            
            // Today
            document.getElementById('icon2').innerText = data.today.icon;
            document.getElementById('max2').innerText = data.today.maxTemp + '°';
            document.getElementById('min2').innerText = data.today.minTemp + '°';
            document.getElementById('rain2').innerText = data.today.rainPrep + '%';
            document.getElementById('appMax2').innerText = data.today.maxApp + '°';
            document.getElementById('appMin2').innerText = data.today.minApp + '°';
            
            // Tomorrow
            document.getElementById('icon3').innerText = data.tomorrow.icon;
            document.getElementById('max3').innerText = data.tomorrow.maxTemp + '°';
            document.getElementById('min3').innerText = data.tomorrow.minTemp + '°';
            document.getElementById('rain3').innerText = data.tomorrow.rainPrep + '%';
            document.getElementById('appMax3').innerText = data.tomorrow.maxApp + '°';
            document.getElementById('appMin3').innerText = data.tomorrow.minApp + '°';
            
            document.getElementById('content').style.display = 'block';
          } catch (e) {
            alert('Error: ' + e);
          } finally {
            document.getElementById('loading').style.display = 'none';
          }
        }
        
        // Initial fetch
        fetchData();
      </script>
    </body>
    </html>
  `);
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Weather App Demo running at http://localhost:${port}/`);
});
