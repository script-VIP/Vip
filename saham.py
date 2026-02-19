import logging
import asyncio
from datetime import datetime, timedelta
import pandas as pd
import numpy as np
import yfinance as yf
import requests
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, MessageHandler, filters, ContextTypes
import pandas_ta as ta
from typing import Dict, List, Tuple, Optional
import json
import aiohttp
import asyncio
from collections import defaultdict

# Konfigurasi logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Token bot Telegram - GANTI DENGAN TOKEN BOT ANDA
BOT_TOKEN = "8165382231:AAG3WjlyJ9Ylaz3pKkQUSmZLi-ovkSxBS7w"

# Daftar sektor saham Indonesia
SECTORS = {
    'AGRICULTURE': ['AALI', 'LSIP', 'SIMP', 'DSNG', 'GOLL', 'JAWA', 'MGRO', 'PALM', 'SIPD', 'SSMS', 'TBLA', 'UNSP'],
    'MINING': ['ADRO', 'ANTM', 'BRMS', 'BUMI', 'BYAN', 'CTRA', 'DOID', 'ELSA', 'GEMS', 'HRUM', 'INCO', 'ITMG', 'KKGI', 'MEDC', 'MITI', 'PTBA', 'PKPK', 'RUIS', 'SMMT', 'TINS', 'TOBA'],
    'BASIC_INDUSTRY': ['ARNA', 'BRPT', 'CPIN', 'DPNS', 'EKAD', 'ETWA', 'IGAR', 'IMAS', 'INAI', 'INCI', 'INTP', 'JPFA', 'KDSI', 'LION', 'MAIN', 'MLBI', 'MYOR', 'PICO', 'PYFA', 'ROTI', 'SMCB', 'SMGR', 'SRSN', 'STTP', 'TCID', 'TOTO', 'ULTJ', 'UNVR'],
    'MISC_INDUSTRY': ['ASII', 'AUTO', 'BATA', 'BOLT', 'DRMA', 'GDYR', 'GJTL', 'IMPC', 'INDS', 'KBLI', 'KBLM', 'LMPI', 'MASA', 'NIPS', 'PRAS', 'PRIM', 'PTSN', 'SCCO', 'SMSM', 'VOKS'],
    'CONSUMER_GOODS': ['ADES', 'ALTO', 'CAMP', 'CEKA', 'CINT', 'COCO', 'DLTA', 'DVLA', 'HMSP', 'ICBP', 'INDF', 'KAEF', 'KINO', 'KLBF', 'LTLS', 'MERK', 'MRAT', 'MYRX', 'PEHA', 'PYFA', 'SCPI', 'SIDO', 'SKBM', 'SKLT', 'STTP', 'TCID', 'TSPC', 'ULTJ', 'UNVR'],
    'PROPERTY': ['ADHI', 'APLN', 'ASRI', 'BCIP', 'BEST', 'BKDP', 'BKSL', 'BSDE', 'CTRA', 'DART', 'DILD', 'DMAS', 'ELTY', 'EMDE', 'FMII', 'FORZ', 'GAMA', 'GPRA', 'JRPT', 'KIJA', 'LAMI', 'LCGP', 'LPKR', 'MABA', 'MDLN', 'MKPI', 'MTLA', 'MTSM', 'NYTA', 'PIKK', 'PLIN', 'PPRO', 'PUDP', 'PWON', 'RBMS', 'RDTX', 'RODA', 'SMRA', 'TARA', 'URBN'],
    'INFRASTRUCTURE': ['ACST', 'BALI', 'CASS', 'CMNP', 'CNKO', 'CMPP', 'DGIK', 'FLMC', 'IDPR', 'IHSI', 'INVS', 'JAPA', 'JAST', 'JATI', 'JAYA', 'JECC', 'JEMA', 'JPRS', 'JSMR', 'KAEF', 'KARW', 'KBLV', 'KBRT', 'KEEN', 'KRAH', 'LAPD', 'LCGP', 'LRNA', 'LSSR', 'MABA', 'MAMI', 'MDRN', 'MFMI', 'MIRA', 'MITT', 'MLPT', 'MMLP', 'MNCN', 'MORA', 'MPOW', 'MTFN', 'MTRA', 'MYRX', 'NELY', 'NIKL', 'NUSA', 'OKAS', 'OMRE', 'PALM', 'PANS', 'PBSA', 'PDPP', 'PEGE', 'PGAS', 'PGLI', 'PJAA', 'PKPK', 'PLAN', 'PLAS', 'PNBN', 'PNIN', 'POOL', 'POWR', 'PPGL', 'PPRE', 'PTPP', 'PUDP', 'PURA', 'PWON', 'RAJA', 'RALS', 'RANC', 'RBMS', 'RDTX', 'REAL', 'RELI', 'RIGS', 'RIMO', 'RODA', 'RUIS', 'SAFE', 'SAME', 'SAPX', 'SCBD', 'SCCO', 'SCMA', 'SDPC', 'SGER', 'SGRO', 'SIDO', 'SILO', 'SIMP', 'SIPD', 'SKBM', 'SKLT', 'SMAR', 'SMDR', 'SMGR', 'SMMA', 'SMMT', 'SMRA', 'SMSM', 'SOCI', 'SONA', 'SPMA', 'SPTO', 'SQMI', 'SRIL', 'SRSN', 'SSIA', 'SSMS', 'STAR', 'STTP', 'SULI', 'SUPR', 'SURY', 'TAMA', 'TARA', 'TBLA', 'TCID', 'TDPM', 'TIFA', 'TINS', 'TIRA', 'TKIM', 'TLKM', 'TMPO', 'TOBA', 'TOTL', 'TPIA', 'TRAM', 'TRIL', 'TRIM', 'TRIO', 'TRIS', 'TRST', 'TSPC', 'TURI', 'UGAR', 'ULTJ', 'UNIC', 'UNIT', 'UNSP', 'UNTR', 'UNVR', 'URBN', 'VRNA', 'VOKS', 'WAPO', 'WEHA', 'WICO', 'WIIM', 'WIKA', 'WINS', 'WINT', 'WOMF', 'WOOD', 'WSBP', 'WSKT', 'YELO', 'YULE', 'ZBRA', 'ZINC']
}

class IndonesianStockBot:
    def __init__(self):
        self.stock_cache = {}
        self.screening_results = {}
        self.user_preferences = defaultdict(dict)
        
    def get_yahoo_code(self, saham):
        """Konversi kode saham Indonesia ke format Yahoo Finance"""
        saham = saham.upper().strip()
        if saham.endswith('.JK'):
            return saham
        return f"{saham}.JK"
    
    async def get_stock_data(self, kode_saham, period="3mo"):
        """Ambil data saham dengan async"""
        cache_key = f"{kode_saham}_{period}"
        
        if cache_key in self.stock_cache:
            data, timestamp = self.stock_cache[cache_key]
            if datetime.now() - timestamp < timedelta(minutes=15):
                return data
        
        try:
            # Gunakan aiohttp untuk async request
            yahoo_code = self.get_yahoo_code(kode_saham)
            
            # Simulasi async - dalam production gunakan aiohttp
            loop = asyncio.get_event_loop()
            stock = await loop.run_in_executor(None, lambda: yf.Ticker(yahoo_code))
            df = await loop.run_in_executor(None, lambda: stock.history(period=period))
            
            if df.empty:
                return None
                
            # Hitung indikator
            df = self.calculate_indicators(df)
            
            # Cache data
            self.stock_cache[cache_key] = (df, datetime.now())
            return df
        except Exception as e:
            logger.error(f"Error mengambil data {kode_saham}: {e}")
            return None
    
    def calculate_indicators(self, df):
        """Hitung semua indikator teknikal"""
        try:
            # Moving Averages
            df['MA5'] = ta.sma(df['Close'], length=5)
            df['MA10'] = ta.sma(df['Close'], length=10)
            df['MA20'] = ta.sma(df['Close'], length=20)
            df['MA50'] = ta.sma(df['Close'], length=50)
            df['MA100'] = ta.sma(df['Close'], length=100)
            df['MA200'] = ta.sma(df['Close'], length=200)
            
            # Exponential MAs
            df['EMA5'] = ta.ema(df['Close'], length=5)
            df['EMA20'] = ta.ema(df['Close'], length=20)
            
            # Parabolic SAR
            psar = ta.psar(df['High'], df['Low'], df['Close'])
            if psar is not None:
                df['PSAR'] = psar.iloc[:, 0] if isinstance(psar, pd.DataFrame) else psar
            
            # Bollinger Bands
            bb = ta.bbands(df['Close'], length=20, std=2)
            if bb is not None:
                df = pd.concat([df, bb], axis=1)
            
            # MACD
            macd = ta.macd(df['Close'])
            if macd is not None:
                df = pd.concat([df, macd], axis=1)
            
            # RSI
            df['RSI'] = ta.rsi(df['Close'], length=14)
            df['RSI_MA'] = ta.sma(df['RSI'], length=5)
            
            # Stochastic
            stoch = ta.stoch(df['High'], df['Low'], df['Close'])
            if stoch is not None:
                df = pd.concat([df, stoch], axis=1)
            
            # Volume indicators
            df['Volume_MA'] = ta.sma(df['Volume'], length=20)
            df['Volume_Ratio'] = df['Volume'] / df['Volume_MA']
            
            # ATR for volatility
            df['ATR'] = ta.atr(df['High'], df['Low'], df['Close'], length=14)
            df['ATR_Percent'] = (df['ATR'] / df['Close']) * 100
            
            # Support & Resistance levels
            df['Resistance'] = df['High'].rolling(window=20).max()
            df['Support'] = df['Low'].rolling(window=20).min()
            
            return df
        except Exception as e:
            logger.error(f"Error calculating indicators: {e}")
            return df
    
    def detect_trading_patterns(self, df):
        """Deteksi pola trading"""
        if df is None or df.empty or len(df) < 20:
            return {}
        
        latest = df.iloc[-1]
        patterns = {}
        
        # Swing Trading Patterns
        patterns['swing'] = self.detect_swing_patterns(df)
        
        # Buy Pagi Jual Sore (BPJS)
        patterns['bpjs'] = self.detect_bpjs_pattern(df)
        
        # Buy Saham Jago Pilih (BSJP)
        patterns['bsjp'] = self.detect_bsjp_pattern(df)
        
        # ARA Hunter
        patterns['ara_hunter'] = self.detect_ara_pattern(df)
        
        # Gap Analysis
        patterns['gap'] = self.detect_gap_pattern(df)
        
        return patterns
    
    def detect_swing_patterns(self, df):
        """Deteksi pola untuk swing trading (1-5 hari)"""
        if len(df) < 10:
            return {}
        
        latest = df.iloc[-1]
        patterns = {}
        
        # Swing Buy Signals
        buy_signals = []
        sell_signals = []
        
        # 1. Bullish Flag Pattern
        if len(df) >= 10:
            recent_high = df['High'].iloc[-6:-1].max()
            recent_low = df['Low'].iloc[-6:-1].min()
            current_close = latest['Close']
            
            if current_close > recent_high and df['Volume'].iloc[-1] > df['Volume_MA'].iloc[-1] * 1.5:
                buy_signals.append("Bullish Flag Breakout")
        
        # 2. RSI Rebound
        if latest['RSI'] < 35 and latest['RSI'] > latest['RSI_MA']:
            buy_signals.append("RSI Rebound from Oversold")
        
        # 3. Moving Average Crossover
        if latest['MA5'] > latest['MA20'] and df['MA5'].iloc[-2] <= df['MA20'].iloc[-2]:
            buy_signals.append("Golden Cross (MA5 > MA20)")
        
        # 4. Volume Spike with Price Up
        if latest['Close'] > latest['MA5'] and latest['Volume_Ratio'] > 2:
            buy_signals.append("Volume Spike + Price Up")
        
        # Sell Signals
        if latest['RSI'] > 75:
            sell_signals.append("Overbought RSI")
        
        if latest['Close'] < latest['MA5'] and latest['Volume_Ratio'] > 1.5:
            sell_signals.append("Breakdown with Volume")
        
        patterns['buy_signals'] = buy_signals
        patterns['sell_signals'] = sell_signals
        patterns['swing_score'] = len(buy_signals) - len(sell_signals)
        
        return patterns
    
    def detect_bpjs_pattern(self, df):
        """Deteksi pola Buy Pagi Jual Sore (intraday)"""
        if len(df) < 2:
            return {}
        
        latest = df.iloc[-1]
        prev = df.iloc[-2]
        
        bpjs = {}
        
        # Intraday momentum indicators
        price_range = (latest['High'] - latest['Low']) / latest['Low'] * 100
        price_change = (latest['Close'] - latest['Open']) / latest['Open'] * 100
        
        # Volume analysis
        volume_surge = latest['Volume_Ratio'] > 2
        
        # Support/Resistance levels
        resistance_break = latest['Close'] > latest['Resistance']
        support_bounce = latest['Low'] > latest['Support'] and latest['Close'] > latest['Open']
        
        # Scoring untuk BPJS
        bpjs_score = 0
        
        if price_change > 1 and volume_surge:
            bpjs_score += 2
            bpjs['signal'] = "STRONG BUY (Volume Spike + Price Up)"
        elif price_change > 0.5 and volume_surge:
            bpjs_score += 1
            bpjs['signal'] = "BUY (Moderate)"
        elif price_change < -1 and volume_surge:
            bpjs_score -= 1
            bpjs['signal'] = "SELL (Distribution)"
        else:
            bpjs['signal'] = "NEUTRAL"
        
        bpjs['score'] = bpjs_score
        bpjs['price_range'] = f"{price_range:.2f}%"
        bpjs['intraday_change'] = f"{price_change:.2f}%"
        
        return bpjs
    
    def detect_bsjp_pattern(self, df):
        """Deteksi pola Buy Saham Jago Pilih (fundamental + teknikal)"""
        if len(df) < 50:
            return {}
        
        latest = df.iloc[-1]
        bsjp = {}
        
        # Komponen penilaian
        technical_score = 0
        fundamental_proxy = 0
        
        # Technical Analysis
        if latest['MA50'] > latest['MA200']:
            technical_score += 2  # Uptrend
            bsjp['trend'] = "UPTREND"
        else:
            technical_score -= 1
            bsjp['trend'] = "DOWNTREND"
        
        # Momentum
        if latest['RSI'] > 50 and latest['RSI'] < 70:
            technical_score += 1
            bsjp['momentum'] = "HEALTHY"
        elif latest['RSI'] >= 70:
            bsjp['momentum'] = "OVERBOUGHT"
        elif latest['RSI'] <= 30:
            bsjp['momentum'] = "OVERSOLD"
        
        # Volume consistency
        volume_consistency = df['Volume_Ratio'].tail(5).mean()
        if volume_consistency > 1.2:
            technical_score += 1
            bsjp['volume'] = "HIGH ACTIVITY"
        elif volume_consistency < 0.8:
            technical_score -= 1
            bsjp['volume'] = "LOW ACTIVITY"
        
        # Volatility (ATR)
        atr_percent = latest['ATR_Percent']
        if atr_percent > 3:
            bsjp['volatility'] = "HIGH"
        elif atr_percent > 1.5:
            bsjp['volatility'] = "MODERATE"
        else:
            bsjp['volatility'] = "LOW"
        
        # Final assessment
        if technical_score >= 3:
            bsjp['recommendation'] = "STRONG BUY"
        elif technical_score >= 1:
            bsjp['recommendation'] = "BUY"
        elif technical_score <= -2:
            bsjp['recommendation'] = "STRONG SELL"
        elif technical_score <= 0:
            bsjp['recommendation'] = "SELL"
        else:
            bsjp['recommendation'] = "HOLD"
        
        bsjp['technical_score'] = technical_score
        
        return bsjp
    
    def detect_ara_pattern(self, df):
        """Deteksi pola untuk ARA (Auto Rejection Atas) Hunter"""
        if len(df) < 10:
            return {}
        
        latest = df.iloc[-1]
        ara = {}
        
        # Hitung kenaikan dalam 5 hari terakhir
        price_5d_ago = df['Close'].iloc[-6] if len(df) > 6 else df['Close'].iloc[0]
        gain_5d = (latest['Close'] - price_5d_ago) / price_5d_ago * 100
        
        # Deteksi potensi ARA
        if gain_5d > 15:
            ara['status'] = "WARNING - SUDAH NAIK SIGNIFIKAN"
            ara['action'] = "HOLD/TAKE PROFIT"
        elif gain_5d > 10:
            ara['status'] = "POTENSI ARA"
            ara['action'] = "WATCH FOR BREAKOUT"
        elif gain_5d > 5:
            ara['status'] = "MULAI BERGERAK"
            ara['action'] = "ACCUMULATE"
        else:
            ara['status'] = "NORMAL"
            ara['action'] = "WAIT"
        
        # Deteksi volume untuk ARA
        if latest['Volume_Ratio'] > 3:
            ara['volume_signal'] = "VOLUME SPIKES - POTENSI ARA"
        elif latest['Volume_Ratio'] > 2:
            ara['volume_signal'] = "VOLUME TINGGI"
        else:
            ara['volume_signal'] = "VOLUME NORMAL"
        
        ara['gain_5d'] = f"{gain_5d:.2f}%"
        ara['volume_ratio'] = f"{latest['Volume_Ratio']:.2f}x"
        
        # Jarak ke ARA (asumsi 25% dari harga)
        ara_price = latest['Close'] * 1.25
        ara['distance_to_ara'] = f"{((ara_price - latest['Close'])/latest['Close']*100):.2f}%"
        
        return ara
    
    def detect_gap_pattern(self, df):
        """Deteksi gap up/down"""
        if len(df) < 2:
            return {}
        
        latest = df.iloc[-1]
        prev = df.iloc[-2]
        
        gap = {}
        
        # Gap Up
        if latest['Low'] > prev['High']:
            gap['type'] = "GAP UP"
            gap['size'] = f"{((latest['Low'] - prev['High'])/prev['High']*100):.2f}%"
            gap['signal'] = "BULLISH"
        
        # Gap Down
        elif latest['High'] < prev['Low']:
            gap['type'] = "GAP DOWN"
            gap['size'] = f"{((prev['Low'] - latest['High'])/prev['Low']*100):.2f}%"
            gap['signal'] = "BEARISH"
        
        # No Gap
        else:
            return {}
        
        # Gap fill probability
        if gap['type'] == "GAP UP":
            gap['probability_fill'] = "HIGH" if latest['Volume_Ratio'] < 1.5 else "LOW"
        else:
            gap['probability_fill'] = "HIGH" if latest['Volume_Ratio'] < 1.5 else "LOW"
        
        return gap
    
    async def screen_stocks(self, strategy="swing"):
        """Screen semua saham berdasarkan strategi"""
        results = []
        
        for sector, stocks in SECTORS.items():
            for stock in stocks:
                try:
                    df = await self.get_stock_data(stock, period="3mo")
                    if df is None:
                        continue
                    
                    patterns = self.detect_trading_patterns(df)
                    
                    if strategy == "swing" and patterns.get('swing', {}).get('swing_score', 0) >= 2:
                        results.append({
                            'stock': stock,
                            'sector': sector,
                            'price': df['Close'].iloc[-1],
                            'score': patterns['swing']['swing_score'],
                            'signals': patterns['swing'].get('buy_signals', [])
                        })
                    
                    elif strategy == "bpjs" and patterns.get('bpjs', {}).get('score', 0) >= 1:
                        results.append({
                            'stock': stock,
                            'sector': sector,
                            'price': df['Close'].iloc[-1],
                            'score': patterns['bpjs']['score'],
                            'signal': patterns['bpjs'].get('signal', '')
                        })
                    
                    elif strategy == "ara" and patterns.get('ara_hunter', {}).get('gain_5d', '0%') > '10%':
                        results.append({
                            'stock': stock,
                            'sector': sector,
                            'price': df['Close'].iloc[-1],
                            'gain_5d': patterns['ara_hunter'].get('gain_5d', ''),
                            'volume': patterns['ara_hunter'].get('volume_signal', '')
                        })
                    
                    # Delay untuk menghindari rate limit
                    await asyncio.sleep(0.1)
                    
                except Exception as e:
                    logger.error(f"Error screening {stock}: {e}")
                    continue
        
        # Sort results
        if strategy == "swing":
            results.sort(key=lambda x: x['score'], reverse=True)
        elif strategy == "bpjs":
            results.sort(key=lambda x: x['score'], reverse=True)
        
        return results[:20]  # Return top 20

# Inisialisasi bot
bot = IndonesianStockBot()

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler untuk perintah /start"""
    welcome_message = """
🚀 *INDONESIAN STOCK TRADING BOT* 🚀

Halo! Saya adalah bot trading saham Indonesia dengan fitur lengkap untuk menganalisis ~900 saham di BEI.

*📊 FITUR UTAMA:*

1️⃣ *Analisis Individual*
   • Ketik kode saham (contoh: BBCA)
   • Lihat semua indikator teknikal

2️⃣ *Screening Strategy*
   /swing - Swing Trading (1-5 hari)
   /bpjs - Buy Pagi Jual Sore (Intraday)
   /bsjp - Buy Saham Jago Pilih
   /ara - ARA Hunter
   /gap - Gap Trading

3️⃣ *Market Overview*
   /topgainers - Top gainers hari ini
   /toplosers - Top losers hari ini
   /volume - Saham dengan volume tertinggi

4️⃣ *Sektor Analysis*
   /sector [nama] - Analisis per sektor
   /watchlist - Buat watchlist pribadi

5️⃣ *Advanced Features*
   /alert [saham] [harga] - Set price alert
   /scan [strategi] - Scan all stocks

6️⃣ *Info & Settings*
   /help - Bantuan lengkap
   /settings - Pengaturan bot

*Contoh:* Ketik `BBCA` untuk analisis detail
    """
    
    keyboard = [
        [InlineKeyboardButton("📈 Swing Trading", callback_data='screen_swing'),
         InlineKeyboardButton("⚡ BPJS", callback_data='screen_bpjs')],
        [InlineKeyboardButton("🎯 BSJP", callback_data='screen_bsjp'),
         InlineKeyboardButton("🚀 ARA Hunter", callback_data='screen_ara')],
        [InlineKeyboardButton("📊 Top Gainers", callback_data='top_gainers'),
         InlineKeyboardButton("📉 Top Losers", callback_data='top_losers')]
    ]
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await update.message.reply_text(
        welcome_message,
        parse_mode='Markdown',
        reply_markup=reply_markup
    )

async def analyze_stock(update: Update, context: ContextTypes.DEFAULT_TYPE, kode_saham: str):
    """Analisis saham individual"""
    try:
        processing_msg = await update.message.reply_text(f"🔍 Menganalisis {kode_saham}...")
        
        # Ambil data
        df = await bot.get_stock_data(kode_saham)
        
        if df is None or df.empty:
            await processing_msg.edit_text(f"❌ Data saham {kode_saham} tidak ditemukan")
            return
        
        # Deteksi pola
        patterns = bot.detect_trading_patterns(df)
        
        # Data terbaru
        latest = df.iloc[-1]
        prev = df.iloc[-2] if len(df) > 1 else latest
        
        # Format pesan
        message = f"""
📈 *ANALISIS {kode_saham}*
━━━━━━━━━━━━━━━━━━━━━
💰 Harga: Rp {latest['Close']:,.0f}
📊 Change: {((latest['Close'] - prev['Close'])/prev['Close']*100):+.2f}%
📅 Volume: {latest['Volume']:,.0f} ({latest['Volume_Ratio']:.2f}x avg)

🎯 *SWING TRADING*
━━━━━━━━━━━━━━━━━━━━━
Score: {patterns.get('swing', {}).get('swing_score', 0)}
Buy Signals:
{chr(10).join(['• ' + s for s in patterns.get('swing', {}).get('buy_signals', ['None'])])}
Sell Signals:
{chr(10).join(['• ' + s for s in patterns.get('swing', {}).get('sell_signals', ['None'])])}

⚡ *BPJS (INTRADAY)*
━━━━━━━━━━━━━━━━━━━━━
Signal: {patterns.get('bpjs', {}).get('signal', 'N/A')}
Range: {patterns.get('bpjs', {}).get('price_range', 'N/A')}

🎯 *BSJP (JAGO PILIH)*
━━━━━━━━━━━━━━━━━━━━━
Trend: {patterns.get('bsjp', {}).get('trend', 'N/A')}
Momentum: {patterns.get('bsjp', {}).get('momentum', 'N/A')}
Volume: {patterns.get('bsjp', {}).get('volume', 'N/A')}
Recommendation: {patterns.get('bsjp', {}).get('recommendation', 'N/A')}

🚀 *ARA HUNTER*
━━━━━━━━━━━━━━━━━━━━━
5D Gain: {patterns.get('ara_hunter', {}).get('gain_5d', 'N/A')}
Status: {patterns.get('ara_hunter', {}).get('status', 'N/A')}
Action: {patterns.get('ara_hunter', {}).get('action', 'N/A')}

📊 *TEKNIKAL*
━━━━━━━━━━━━━━━━━━━━━
RSI(14): {latest['RSI']:.2f}
MACD: {latest.get('MACD_12_26_9', 0):.2f}
BB Position: {'Upper' if latest['Close'] > latest.get('BBU_20_2.0', 0) else 'Middle' if latest['Close'] > latest.get('BBL_20_2.0', 0) else 'Lower'}
ATR: {latest['ATR_Percent']:.2f}%

MA Status:
• MA5: {latest['MA5']:.0f} ({'Above' if latest['Close'] > latest['MA5'] else 'Below'})
• MA20: {latest['MA20']:.0f} ({'Above' if latest['Close'] > latest['MA20'] else 'Below'})
• MA50: {latest['MA50']:.0f} ({'Above' if latest['Close'] > latest['MA50'] else 'Below'})

💡 *RECOMMENDATION*
━━━━━━━━━━━━━━━━━━━━━
{patterns.get('bsjp', {}).get('recommendation', 'HOLD')}
        """
        
        await processing_msg.delete()
        await update.message.reply_text(message, parse_mode='Markdown')
        
    except Exception as e:
        logger.error(f"Error: {e}")
        await update.message.reply_text(f"❌ Error: {str(e)}")

async def screen_swing(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Screen untuk swing trading"""
    msg = await update.message.reply_text("🔍 Screening semua saham untuk swing trading... (Ini akan memakan waktu)")
    
    try:
        results = await bot.screen_stocks("swing")
        
        if not results:
            await msg.edit_text("❌ Tidak menemukan saham dengan sinyal swing trading saat ini")
            return
        
        message = "📈 *TOP SWING TRADING CANDIDATES*\n━━━━━━━━━━━━━━━━━━━━━\n\n"
        
        for r in results[:10]:  # Top 10
            message += f"• *{r['stock']}* ({r['sector']})\n"
            message += f"  Price: Rp {r['price']:,.0f}\n"
            message += f"  Score: {r['score']}\n"
            message += f"  Signals: {', '.join(r['signals'][:2])}\n\n"
        
        await msg.edit_text(message, parse_mode='Markdown')
        
    except Exception as e:
        await msg.edit_text(f"❌ Error: {str(e)}")

async def screen_bpjs(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Screen untuk BPJS (intraday)"""
    msg = await update.message.reply_text("🔍 Screening untuk BPJS (Buy Pagi Jual Sore)...")
    
    try:
        results = await bot.screen_stocks("bpjs")
        
        if not results:
            await msg.edit_text("❌ Tidak menemukan saham dengan sinyal BPJS saat ini")
            return
        
        message = "⚡ *TOP BPJS CANDIDATES (INTRADAY)*\n━━━━━━━━━━━━━━━━━━━━━\n\n"
        
        for r in results[:10]:
            message += f"• *{r['stock']}* ({r['sector']})\n"
            message += f"  Price: Rp {r['price']:,.0f}\n"
            message += f"  Signal: {r['signal']}\n"
            message += f"  Score: {r['score']}\n\n"
        
        await msg.edit_text(message, parse_mode='Markdown')
        
    except Exception as e:
        await msg.edit_text(f"❌ Error: {str(e)}")

async def screen_ara(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Screen untuk ARA Hunter"""
    msg = await update.message.reply_text("🔍 Screening untuk ARA Hunter...")
    
    try:
        results = await bot.screen_stocks("ara")
        
        if not results:
            await msg.edit_text("❌ Tidak menemukan saham dengan potensi ARA saat ini")
            return
        
        message = "🚀 *ARA HUNTER - POTENSI AUTO REJECTION*\n━━━━━━━━━━━━━━━━━━━━━\n\n"
        
        for r in results[:10]:
            message += f"• *{r['stock']}* ({r['sector']})\n"
            message += f"  Price: Rp {r['price']:,.0f}\n"
            message += f"  5D Gain: {r['gain_5d']}\n"
            message += f"  Volume: {r['volume']}\n\n"
        
        await msg.edit_text(message, parse_mode='Markdown')
        
    except Exception as e:
        await msg.edit_text(f"❌ Error: {str(e)}")

async def top_gainers(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Menampilkan top gainers"""
    # Implementasi sederhana - dalam production ambil dari API
    await update.message.reply_text("📊 Fitur Top Gainers akan segera hadir!")

async def top_losers(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Menampilkan top losers"""
    await update.message.reply_text("📉 Fitur Top Losers akan segera hadir!")

async def sector_analysis(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Analisis per sektor"""
    if not context.args:
        sectors = list(SECTORS.keys())
        message = "📊 *SEKTOR TERSEDIA*\n━━━━━━━━━━━━━━━━\n\n"
        for i, sector in enumerate(sectors, 1):
            message += f"{i}. {sector}\n"
        message += "\nGunakan: /sector [nama sektor]"
        await update.message.reply_text(message, parse_mode='Markdown')
        return
    
    sector_name = ' '.join(context.args).upper()
    if sector_name in SECTORS:
        stocks = SECTORS[sector_name]
        message = f"📊 *SEKTOR {sector_name}*\n━━━━━━━━━━━━━━━━\n\n"
        message += f"Total saham: {len(stocks)}\n\n"
        message += "Saham unggulan:\n"
        # Tampilkan 10 pertama
        for stock in stocks[:10]:
            message += f"• {stock}\n"
        
        await update.message.reply_text(message, parse_mode='Markdown')
    else:
        await update.message.reply_text("❌ Sektor tidak ditemukan")

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler untuk pesan teks biasa"""
    text = update.message.text.strip().upper()
    
    # Cek apakah input adalah kode saham (hanya huruf, 4-5 karakter)
    if text.isalpha() and 3 <= len(text) <= 5:
        await analyze_stock(update, context, text)
    else:
        await update.message.reply_text(
            "❌ Format salah. Masukkan kode saham (contoh: BBCA) atau gunakan /help untuk bantuan"
        )

async def button_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler untuk callback button"""
    query = update.callback_query
    await query.answer()
    
    if query.data == 'screen_swing':
        await screen_swing(update, context)
    elif query.data == 'screen_bpjs':
        await screen_bpjs(update, context)
    elif query.data == 'screen_ara':
        await screen_ara(update, context)
    elif query.data == 'top_gainers':
        await top_gainers(update, context)
    elif query.data == 'top_losers':
        await top_losers(update, context)

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Menampilkan bantuan lengkap"""
    help_text = """
📚 *BANTUAN LENGKAP*

*CARA MENGGUNAKAN BOT:*

1️⃣ *ANALISIS INDIVIDUAL*
   • Ketik kode saham (BBCA, ASII, dll)
   • Lihat semua indikator teknikal
   • Deteksi pola trading

2️⃣ *SCREENING OTOMATIS*
   /swing - Cari saham untuk swing trading
   /bpjs - Cari saham untuk intraday
   /ara - Cari saham potensi ARA
   /gap - Cari saham dengan gap

3️⃣ *MARKET OVERVIEW*
   /topgainers - Saham dengan kenaikan tertinggi
   /toplosers - Saham dengan penurunan tertinggi
   /volume - Saham dengan volume terbesar

4️⃣ *SEKTOR ANALYSIS*
   /sector - Lihat daftar sektor
   /sector [nama] - Lihat saham di sektor

5️⃣ *WATCHLIST (COMING SOON)*
   /watchlist add [kode] - Tambah ke watchlist
   /watchlist remove [kode] - Hapus dari watchlist
   /watchlist show - Lihat watchlist

6️⃣ *ALERT (COMING SOON)*
   /alert [kode] [harga] - Set price alert
   /alerts - Lihat alerts aktif

*STRATEGI TRADING:*

• *SWING TRADING* (1-5 hari)
  Cari saham dengan momentum kuat

• *BPJS* (Buy Pagi Jual Sore)
  Intraday trading dengan volume tinggi

• *BSJP* (Buy Saham Jago Pilih)
  Kombinasi teknikal + fundamental

• *ARA HUNTER*
  Cari saham potensi Auto Rejection

*INDIKATOR TEKNIKAL:*
• Moving Averages (5,10,20,50,100,200)
• RSI (14)
• MACD
• Bollinger Bands
• Stochastic
• Parabolic SAR
• Volume Analysis
• ATR (Volatility)
• Support & Resistance

*DISCLAIMER:*
Bot ini untuk analisis dan edukasi, bukan rekomendasi jual/beli. Selalu lakukan riset sendiri sebelum trading.
    """
    
    await update.message.reply_text(help_text, parse_mode='Markdown')

def main():
    """Fungsi utama"""
    # Buat aplikasi
    application = Application.builder().token(BOT_TOKEN).build()
    
    # Register command handlers
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("swing", screen_swing))
    application.add_handler(CommandHandler("bpjs", screen_bpjs))
    application.add_handler(CommandHandler("ara", screen_ara))
    application.add_handler(CommandHandler("topgainers", top_gainers))
    application.add_handler(CommandHandler("toplosers", top_losers))
    application.add_handler(CommandHandler("sector", sector_analysis))
    
    # Handler untuk callback button
    application.add_handler(CallbackQueryHandler(button_callback))
    
    # Handler untuk pesan teks biasa (kode saham)
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    # Start bot
    print("🤖 Bot Trading Saham Indonesia berjalan...")
    print("📊 Mendukung ~900 saham BEI")
    print("⚡ Fitur: Swing, BPJS, BSJP, ARA Hunter")
    print("Tekan Ctrl+C untuk berhenti")
    
    application.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == '__main__':
    main()
