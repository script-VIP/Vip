import logging
import asyncio
from datetime import datetime, timedelta
import pandas as pd
import numpy as np
import yfinance as yf
import requests
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, MessageHandler, filters, ContextTypes
import ta
from typing import Dict, List, Tuple, Optional
import json
import aiohttp
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
            yahoo_code = self.get_yahoo_code(kode_saham)
            loop = asyncio.get_event_loop()
            stock = await loop.run_in_executor(None, lambda: yf.Ticker(yahoo_code))
            df = await loop.run_in_executor(None, lambda: stock.history(period=period))

            if df.empty:
                return None

            df = self.calculate_indicators(df)
            self.stock_cache[cache_key] = (df, datetime.now())
            return df
        except Exception as e:
            logger.error(f"Error mengambil data {kode_saham}: {e}")
            return None

    def calculate_indicators(self, df):
        """Hitung semua indikator teknikal"""
        try:
            # Moving Averages
            df['MA5'] = df['Close'].rolling(window=5).mean()
            df['MA10'] = df['Close'].rolling(window=10).mean()
            df['MA20'] = df['Close'].rolling(window=20).mean()
            df['MA50'] = df['Close'].rolling(window=50).mean()
            df['MA100'] = df['Close'].rolling(window=100).mean()
            df['MA200'] = df['Close'].rolling(window=200).mean()

            # RSI
            df['RSI'] = ta.momentum.RSIIndicator(df['Close'], window=14).rsi()

            # Volume indicators
            df['Volume_MA'] = df['Volume'].rolling(window=20).mean()
            df['Volume_Ratio'] = df['Volume'] / df['Volume_MA']

            # ATR
            df['ATR'] = ta.volatility.AverageTrueRange(df['High'], df['Low'], df['Close'], window=14).average_true_range()
            df['ATR_Percent'] = (df['ATR'] / df['Close']) * 100

            # Support & Resistance
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

        patterns = {}
        patterns['swing'] = self.detect_swing_patterns(df)
        patterns['bpjs'] = self.detect_bpjs_pattern(df)
        patterns['ara_hunter'] = self.detect_ara_pattern(df)
        return patterns

    def detect_swing_patterns(self, df):
        """Deteksi pola swing trading"""
        if len(df) < 10:
            return {}

        latest = df.iloc[-1]
        buy_signals = []
        sell_signals = []

        if latest['RSI'] < 35:
            buy_signals.append("RSI Oversold")

        if latest['Close'] > latest['MA5'] and latest['Volume_Ratio'] > 1.5:
            buy_signals.append("Volume Spike + Price Up")

        if latest['RSI'] > 75:
            sell_signals.append("RSI Overbought")

        return {
            'buy_signals': buy_signals,
            'sell_signals': sell_signals,
            'swing_score': len(buy_signals) - len(sell_signals)
        }

    def detect_bpjs_pattern(self, df):
        """Deteksi pola intraday"""
        if len(df) < 2:
            return {}

        latest = df.iloc[-1]
        price_change = (latest['Close'] - latest['Open']) / latest['Open'] * 100
        volume_surge = latest['Volume_Ratio'] > 2

        bpjs_score = 0
        signal = "NEUTRAL"

        if price_change > 1 and volume_surge:
            bpjs_score = 2
            signal = "STRONG BUY"
        elif price_change > 0.5 and volume_surge:
            bpjs_score = 1
            signal = "BUY"
        elif price_change < -1 and volume_surge:
            bpjs_score = -1
            signal = "SELL"

        return {
            'signal': signal,
            'score': bpjs_score,
            'intraday_change': f"{price_change:.2f}%"
        }

    def detect_ara_pattern(self, df):
        """Deteksi potensi ARA"""
        if len(df) < 5:
            return {}

        latest = df.iloc[-1]
        price_5d_ago = df['Close'].iloc[-5]
        gain_5d = (latest['Close'] - price_5d_ago) / price_5d_ago * 100

        return {
            'gain_5d': f"{gain_5d:.2f}%",
            'volume_ratio': f"{latest['Volume_Ratio']:.2f}x",
            'status': "POTENSI ARA" if gain_5d > 10 else "NORMAL"
        }

# Inisialisasi bot
bot = IndonesianStockBot()

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    welcome_message = """
🚀 *BOT SAHAM INDONESIA* 🚀

Fitur:
• Analisis individual (ketik kode saham)
• Swing Trading Scanner
• BPJS (Buy Pagi Jual Sore)
• ARA Hunter

Contoh: ketik `BBCA` untuk analisis
    """
    await update.message.reply_text(welcome_message, parse_mode='Markdown')

async def analyze_stock(update: Update, context: ContextTypes.DEFAULT_TYPE, kode_saham: str):
    try:
        msg = await update.message.reply_text(f"🔍 Menganalisis {kode_saham}...")
        df = await bot.get_stock_data(kode_saham)

        if df is None or df.empty:
            await msg.edit_text(f"❌ Data {kode_saham} tidak ditemukan")
            return

        patterns = bot.detect_trading_patterns(df)
        latest = df.iloc[-1]
        prev = df.iloc[-2] if len(df) > 1 else latest

        response = f"""
📈 *{kode_saham}*
💰 Harga: Rp {latest['Close']:,.0f}
📊 Change: {((latest['Close'] - prev['Close'])/prev['Close']*100):+.2f}%
📊 RSI: {latest['RSI']:.2f}

⚡ *BPJS*: {patterns.get('bpjs', {}).get('signal', 'N/A')}
🚀 *ARA*: {patterns.get('ara_hunter', {}).get('status', 'N/A')} ({patterns.get('ara_hunter', {}).get('gain_5d', '0%')})

🎯 *Swing Score*: {patterns.get('swing', {}).get('swing_score', 0)}
        """
        await msg.edit_text(response, parse_mode='Markdown')
    except Exception as e:
        await update.message.reply_text(f"❌ Error: {str(e)}")

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text.strip().upper()
    if text.isalpha() and 3 <= len(text) <= 5:
        await analyze_stock(update, context, text)
    else:
        await update.message.reply_text("❌ Masukkan kode saham (contoh: BBCA)")

def main():
    app = Application.builder().token(BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    print("🤖 Bot berjalan...")
    app.run_polling()

if __name__ == '__main__':
    main()
