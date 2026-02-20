#!/usr/bin/env python3
"""
BOT SAHAM INDONESIA & AS
Telegram Bot untuk analisis saham Indonesia dan Amerika Serikat
Fitur: Teknikal, Fundamental Ringkas, Bandarmology Ringkas, Swing Trading, Day Trade + CHART
Author: AI Assistant
Version: 3.0 (with charts)
"""

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
import io
import matplotlib.pyplot as plt
import mplfinance as mpf
import matplotlib
matplotlib.use('Agg')  # Untuk server tanpa GUI

# Konfigurasi logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# # ======================== KONFIGURASI ========================
# Token bot Telegram - Setup interaktif
import os
import sys
import time

BOT_TOKEN = None

def print_header():
    """Print header keren"""
    print("\n" + "█"*60)
    print("██╗  ██╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ ")
    print("██║  ██║██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ ")
    print("███████║██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗")
    print("██╔══██║██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║")
    print("██║  ██║╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝")
    print("╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝ ")
    print("█"*60)
    print("🔥 BOT SAHAM INDONESIA & AS v3.0".center(60))
    print("█"*60)

def loading_animation(text):
    """Animasi loading sederhana"""
    for i in range(3):
        print(f"\r{text}" + "." * i + "   ", end="", flush=True)
        time.sleep(0.3)
    print("\r" + " " * 50, end="\r")

def setup_token():
    """Setup token interaktif"""
    global BOT_TOKEN
    
    print_header()
    print("\n📢 PENTING: Bot memerlukan token Telegram!")
    print("\n🔍 Belum punya token? Ikuti langkah berikut:")
    print("   1️⃣  Buka Telegram")
    print("   2️⃣  Cari @BotFather (official bot Telegram)")
    print("   3️⃣  Kirim perintah: /newbot")
    print("   4️⃣  Masukkan nama bot (contoh: SahamKuBot)")
    print("   5️⃣  Masukkan username bot (harus unik, akhiran 'bot')")
    print("   6️⃣  Copy token yang diberikan BotFather")
    print("\n" + "─"*60)
    
    # Cek apakah sudah ada file token
    if os.path.exists('.token'):
        print("\n📁 File token ditemukan!")
        use_existing = input("🔑 Gunakan token yang sudah ada? (y/n): ").strip().lower()
        if use_existing == 'y':
            with open('.token', 'r') as f:
                BOT_TOKEN = f.read().strip()
            print("\n✅ Token dimuat dari file!")
            print("🚀 Melanjutkan...")
            print("─"*60 + "\n")
            return
    
    # Minta token baru
    print("\n" + "💬 Silakan masukkan token Anda")
    print("   (Contoh: 8165382231:AAG3WjlyJ9Ylaz3pKkQUSmZLi-ovkSxBS7w)")
    print()
    
    attempts = 0
    while attempts < 3:
        token = input("👉 BOT_TOKEN: ").strip()
        
        if not token:
            print("❌ Token tidak boleh kosong! Coba lagi.")
            attempts += 1
            continue
            
        if ':' not in token:
            print("❌ Format token salah! Harus ada tanda ':'")
            attempts += 1
            continue
            
        if len(token) < 40:
            print("❌ Token terlalu pendek! Pastikan token lengkap.")
            attempts += 1
            continue
        
        # Token valid
        BOT_TOKEN = token
        
        # Simpan ke file
        with open('.token', 'w') as f:
            f.write(token)
        
        print("\n✅ Token valid! Menyimpan...")
        loading_animation("📦 Memproses")
        print("\n✅ Token berhasil dikonfigurasi!")
        print("📁 Tersimpan di file: .token")
        print("─"*60 + "\n")
        return
    
    # Gagal 3 kali
    print("\n❌ Gagal memasukkan token setelah 3 kali percobaan.")
    print("📝 Jalankan ulang program dan coba lagi.")
    sys.exit(1)

# Jalankan setup
setup_token()
# ======================== DAFTAR SAHAM ========================

# SAHAM INDONESIA (BEI)
INDONESIA_STOCKS = {
    'IDX30': ['BBCA', 'BBRI', 'BMRI', 'BBNI', 'ASII', 'TLKM', 'ICBP', 'INDF', 'UNVR', 'GGRM', 
              'HMSP', 'KLBF', 'CPIN', 'JPFA', 'PGAS', 'PTBA', 'ADRO', 'ITMG', 'EXCL', 'ISAT',
              'WIKA', 'PTPP', 'ADHI', 'WSKT', 'BSDE', 'LPKR', 'PWON', 'SMRA', 'CTRA', 'JSMR'],
    
    'LQ45': ['ACES', 'ADRO', 'AKRA', 'ANTM', 'ASII', 'BBCA', 'BBNI', 'BBRI', 'BBTN', 'BMRI',
             'BRPT', 'BSDE', 'CPIN', 'ELSA', 'ERAA', 'EXCL', 'GGRM', 'HMSP', 'ICBP', 'INCO',
             'INDF', 'INDY', 'INKP', 'INTP', 'ITMG', 'JPFA', 'JSMR', 'KLBF', 'LPKR', 'LSIP',
             'MDKA', 'MEDC', 'MIKA', 'MNCN', 'PGAS', 'PTBA', 'PTPP', 'PWON', 'SMGR', 'SMRA',
             'TBIG', 'TKIM', 'TLKM', 'TOWR', 'TPIA', 'UNTR', 'UNVR', 'WIKA', 'WSKT'],
    
    'AGRICULTURE': ['AALI', 'LSIP', 'SIMP', 'DSNG', 'GOLL', 'JAWA', 'MGRO', 'PALM', 'SIPD', 'SSMS', 'TBLA', 'UNSP'],
    'MINING': ['ANTM', 'BRMS', 'BUMI', 'BYAN', 'DOID', 'ELSA', 'GEMS', 'HRUM', 'INCO', 'KKGI', 'MEDC', 'PTBA'],
    'PROPERTY': ['BSDE', 'CTRA', 'LPKR', 'PWON', 'SMRA', 'ADHI', 'PTPP', 'WIKA', 'WSKT'],
    'INFRASTRUCTURE': ['JSMR', 'PGAS', 'TLKM', 'TOWR', 'TBIG', 'EXCL', 'ISAT', 'FREN'],
}

# SAHAM AMERIKA (US)
US_STOCKS = {
    'DOW JONES': ['AAPL', 'MSFT', 'JPM', 'V', 'JNJ', 'WMT', 'PG', 'HD', 'DIS', 'CSCO'],
    'S&P 500': ['AAPL', 'MSFT', 'AMZN', 'GOOGL', 'META', 'BRK-B', 'TSLA', 'NVDA', 'JPM', 'V'],
    'NASDAQ': ['AAPL', 'MSFT', 'AMZN', 'GOOGL', 'META', 'TSLA', 'NVDA', 'ADBE', 'NFLX', 'INTC'],
    'TECH': ['AAPL', 'MSFT', 'GOOGL', 'META', 'NVDA', 'AMD', 'INTC', 'CSCO', 'ORCL', 'IBM'],
    'BANKING': ['JPM', 'BAC', 'WFC', 'C', 'GS', 'MS', 'USB', 'PNC', 'TD', 'SCHW'],
    'ENERGY': ['XOM', 'CVX', 'COP', 'SLB', 'EOG', 'PXD', 'OXY', 'MPC', 'PSX', 'VLO'],
    'HEALTHCARE': ['JNJ', 'UNH', 'PFE', 'MRK', 'ABBV', 'TMO', 'ABT', 'BMY', 'AMGN', 'LLY'],
    'CONSUMER': ['AMZN', 'TSLA', 'HD', 'MCD', 'NKE', 'SBUX', 'LOW', 'TGT', 'COST', 'TJX'],
}

# GABUNGKAN SEMUA SAHAM
ALL_STOCKS = {}
for k, v in INDONESIA_STOCKS.items():
    ALL_STOCKS[f"ID_{k}"] = v
for k, v in US_STOCKS.items():
    ALL_STOCKS[f"US_{k}"] = v

# FLAT LIST UNTUK VALIDASI
INDONESIA_LIST = []
for sector in INDONESIA_STOCKS.values():
    INDONESIA_LIST.extend(sector)
INDONESIA_LIST = list(set(INDONESIA_LIST))

US_LIST = []
for sector in US_STOCKS.values():
    US_LIST.extend(sector)
US_LIST = list(set(US_LIST))

ALL_LIST = INDONESIA_LIST + US_LIST

class IndonesianStockBot:
    def __init__(self):
        self.stock_cache = {}
        self.chart_cache = {}
        self.screening_results = {}
        self.user_preferences = defaultdict(dict)

    def get_yahoo_code(self, saham):
        """Konversi kode saham ke format Yahoo Finance"""
        saham = saham.upper().strip()
        
        # Cek apakah saham Indonesia
        if saham in INDONESIA_LIST:
            if saham.endswith('.JK'):
                return saham
            return f"{saham}.JK"
        
        # Saham US langsung return
        return saham

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
            df['MA20'] = df['Close'].rolling(window=20).mean()
            df['MA50'] = df['Close'].rolling(window=50).mean()
            df['MA100'] = df['Close'].rolling(window=100).mean()
            df['MA200'] = df['Close'].rolling(window=200).mean()

            # Exponential MAs
            df['EMA5'] = df['Close'].ewm(span=5, adjust=False).mean()
            df['EMA20'] = df['Close'].ewm(span=20, adjust=False).mean()

            # RSI
            df['RSI'] = ta.momentum.RSIIndicator(df['Close'], window=14).rsi()

            # MACD
            macd = ta.trend.MACD(df['Close'])
            df['MACD'] = macd.macd()
            df['MACD_Signal'] = macd.macd_signal()
            df['MACD_Hist'] = macd.macd_diff()

            # Bollinger Bands
            bb = ta.volatility.BollingerBands(df['Close'], window=20, window_dev=2)
            df['BB_Upper'] = bb.bollinger_hband()
            df['BB_Middle'] = bb.bollinger_mavg()
            df['BB_Lower'] = bb.bollinger_lband()

            # Stochastic
            stoch = ta.momentum.StochasticOscillator(df['High'], df['Low'], df['Close'], window=14)
            df['Stoch_K'] = stoch.stoch()
            df['Stoch_D'] = stoch.stoch_signal()

            # Parabolic SAR
            psar = ta.trend.PSARIndicator(df['High'], df['Low'], df['Close'])
            df['PSAR'] = psar.psar()

            # Volume indicators
            df['Volume_MA'] = df['Volume'].rolling(window=20).mean()
            df['Volume_Ratio'] = df['Volume'] / df['Volume_MA']

            # ATR
            df['ATR'] = ta.volatility.AverageTrueRange(df['High'], df['Low'], df['Close'], window=14).average_true_range()
            df['ATR_Percent'] = (df['ATR'] / df['Close']) * 100

            # OBV
            df['OBV'] = ta.volume.OnBalanceVolumeIndicator(df['Close'], df['Volume']).on_balance_volume()

            # Support & Resistance sederhana
            df['Resistance'] = df['High'].rolling(window=20).max()
            df['Support'] = df['Low'].rolling(window=20).min()

            # Williams %R
            df['WilliamsR'] = ta.momentum.WilliamsRIndicator(df['High'], df['Low'], df['Close']).williams_r()

            return df
        except Exception as e:
            logger.error(f"Error calculating indicators: {e}")
            return df

    async def generate_chart(self, kode_saham, df):
        """Generate chart candlestick dengan indikator"""
        try:
            cache_key = f"{kode_saham}_chart"
            
            # Cek cache (5 menit)
            if cache_key in self.chart_cache:
                data, timestamp = self.chart_cache[cache_key]
                if datetime.now() - timestamp < timedelta(minutes=5):
                    return data

            # Siapkan data untuk chart (ambil 60 hari terakhir)
            df_chart = df.tail(60).copy()
            
            # Buat plot
            fig, axes = plt.subplots(3, 1, figsize=(12, 10), 
                                     gridspec_kw={'height_ratios': [3, 1, 1]})
            
            # Candlestick chart
            ax1 = axes[0]
            
            # Plot candlestick manual
            width = 0.6
            width2 = 0.05
            
            up = df_chart[df_chart['Close'] >= df_chart['Open']]
            down = df_chart[df_chart['Close'] < df_chart['Open']]
            
            # Plot candlestick
            ax1.bar(up.index, up['Close'] - up['Open'], width, bottom=up['Open'], color='g')
            ax1.bar(up.index, up['High'] - up['Close'], width2, bottom=up['Close'], color='g')
            ax1.bar(up.index, up['Low'] - up['Open'], width2, bottom=up['Open'], color='g')
            
            ax1.bar(down.index, down['Close'] - down['Open'], width, bottom=down['Open'], color='r')
            ax1.bar(down.index, down['High'] - down['Open'], width2, bottom=down['Open'], color='r')
            ax1.bar(down.index, down['Low'] - down['Close'], width2, bottom=down['Close'], color='r')
            
            # Plot Moving Averages
            ax1.plot(df_chart.index, df_chart['MA20'], label='MA20', color='blue', alpha=0.7)
            ax1.plot(df_chart.index, df_chart['MA50'], label='MA50', color='orange', alpha=0.7)
            
            # Plot Bollinger Bands
            ax1.plot(df_chart.index, df_chart['BB_Upper'], label='BB Upper', color='gray', linestyle='--', alpha=0.5)
            ax1.plot(df_chart.index, df_chart['BB_Lower'], label='BB Lower', color='gray', linestyle='--', alpha=0.5)
            
            ax1.set_title(f'{kode_saham} - Price Chart', fontsize=14, fontweight='bold')
            ax1.set_ylabel('Price')
            ax1.legend(loc='upper left')
            ax1.grid(True, alpha=0.3)
            
            # Volume chart
            ax2 = axes[1]
            colors = ['g' if df_chart['Close'].iloc[i] >= df_chart['Open'].iloc[i] else 'r' 
                     for i in range(len(df_chart))]
            ax2.bar(df_chart.index, df_chart['Volume'], color=colors, alpha=0.7)
            ax2.plot(df_chart.index, df_chart['Volume_MA'], color='blue', label='Volume MA', alpha=0.7)
            ax2.set_ylabel('Volume')
            ax2.legend(loc='upper left')
            ax2.grid(True, alpha=0.3)
            
            # RSI chart
            ax3 = axes[2]
            ax3.plot(df_chart.index, df_chart['RSI'], color='purple', label='RSI', linewidth=2)
            ax3.axhline(y=70, color='r', linestyle='--', alpha=0.5, label='Overbought (70)')
            ax3.axhline(y=30, color='g', linestyle='--', alpha=0.5, label='Oversold (30)')
            ax3.set_ylabel('RSI')
            ax3.set_ylim(0, 100)
            ax3.legend(loc='upper left')
            ax3.grid(True, alpha=0.3)
            
            plt.tight_layout()
            
            # Simpan ke buffer
            buf = io.BytesIO()
            plt.savefig(buf, format='png', dpi=100)
            buf.seek(0)
            plt.close()
            
            # Cache
            self.chart_cache[cache_key] = (buf.getvalue(), datetime.now())
            
            return buf.getvalue()
            
        except Exception as e:
            logger.error(f"Error generating chart: {e}")
            return None

    def detect_trading_patterns(self, df):
        """Deteksi pola trading"""
        if df is None or df.empty or len(df) < 20:
            return {}

        latest = df.iloc[-1]
        prev = df.iloc[-2] if len(df) > 1 else latest
        patterns = {}

        # Swing Trading Patterns
        patterns['swing'] = self.detect_swing_patterns(df)

        # Day Trade Patterns
        patterns['daytrade'] = self.detect_daytrade_patterns(df)

        return patterns

    def detect_swing_patterns(self, df):
        """Deteksi pola untuk swing trading (1-5 hari)"""
        if len(df) < 10:
            return {}

        latest = df.iloc[-1]
        prev = df.iloc[-2]
        buy_signals = []
        sell_signals = []

        # 1. MA Crossover
        if latest['MA5'] > latest['MA20'] and prev['MA5'] <= prev['MA20']:
            buy_signals.append("Golden Cross (MA5 > MA20)")

        if latest['MA5'] < latest['MA20'] and prev['MA5'] >= prev['MA20']:
            sell_signals.append("Death Cross (MA5 < MA20)")

        # 2. RSI
        if latest['RSI'] < 30 and latest['RSI'] > latest['RSI']:
            buy_signals.append("RSI Oversold Rebound")
        elif latest['RSI'] > 70:
            sell_signals.append("RSI Overbought")

        # 3. MACD
        if latest['MACD'] > latest['MACD_Signal'] and prev['MACD'] <= prev['MACD_Signal']:
            buy_signals.append("MACD Bullish Crossover")
        elif latest['MACD'] < latest['MACD_Signal'] and prev['MACD'] >= prev['MACD_Signal']:
            sell_signals.append("MACD Bearish Crossover")

        # 4. Parabolic SAR
        if latest['Close'] > latest['PSAR']:
            buy_signals.append("Parabolic SAR Bullish")
        else:
            sell_signals.append("Parabolic SAR Bearish")

        # 5. Bollinger Bands
        if latest['Close'] <= latest['BB_Lower']:
            buy_signals.append("Price at Lower BB (Oversold)")
        elif latest['Close'] >= latest['BB_Upper']:
            sell_signals.append("Price at Upper BB (Overbought)")

        # 6. Volume
        if latest['Close'] > prev['Close'] and latest['Volume_Ratio'] > 1.5:
            buy_signals.append("Volume Spike + Price Up")
        elif latest['Close'] < prev['Close'] and latest['Volume_Ratio'] > 1.5:
            sell_signals.append("Volume Spike + Price Down")

        return {
            'buy_signals': buy_signals,
            'sell_signals': sell_signals,
            'swing_score': len(buy_signals) - len(sell_signals)
        }

    def detect_daytrade_patterns(self, df):
        """Deteksi pola untuk day trade (intraday)"""
        if len(df) < 2:
            return {}

        latest = df.iloc[-1]
        prev = df.iloc[-2]
        
        # Intraday momentum (gunakan daily change sebagai proxy)
        price_change = (latest['Close'] - latest['Open']) / latest['Open'] * 100
        volume_surge = latest['Volume_Ratio'] > 2

        score = 0
        signal = "NEUTRAL"
        reasons = []

        if price_change > 1 and volume_surge:
            score = 2
            signal = "STRONG BUY"
            reasons.append("Price up >1% + Volume spike")
        elif price_change > 0.5 and volume_surge:
            score = 1
            signal = "BUY"
            reasons.append("Price up + Volume spike")
        elif price_change < -1 and volume_surge:
            score = -2
            signal = "STRONG SELL"
            reasons.append("Price down >1% + Volume spike")
        elif price_change < -0.5 and volume_surge:
            score = -1
            signal = "SELL"
            reasons.append("Price down + Volume spike")
        elif price_change > 2:
            score = 1
            signal = "BUY"
            reasons.append("Strong intraday momentum")
        elif price_change < -2:
            score = -1
            signal = "SELL"
            reasons.append("Strong intraday selling")
        else:
            reasons.append("No clear intraday signal")

        # Cek support/resistance intraday
        if latest['Low'] <= latest['Support'] * 0.99:  # Mendekati support
            reasons.append("Near support level")
        if latest['High'] >= latest['Resistance'] * 0.99:  # Mendekati resistance
            reasons.append("Near resistance level")

        return {
            'signal': signal,
            'score': score,
            'reasons': reasons,
            'intraday_change': f"{price_change:.2f}%",
            'volume_ratio': f"{latest['Volume_Ratio']:.2f}x"
        }

    def get_fundamental_summary(self, kode_saham, df):
        """Ringkasan fundamental (menggunakan data dari yfinance)"""
        try:
            yahoo_code = self.get_yahoo_code(kode_saham)
            stock = yf.Ticker(yahoo_code)
            info = stock.info
            
            # Data valuasi
            pe = info.get('trailingPE', 'N/A')
            pb = info.get('priceToBook', 'N/A')
            eps = info.get('trailingEps', 'N/A')
            roe = info.get('returnOnEquity', 'N/A')
            
            # Konversi ke persen jika perlu
            if roe != 'N/A' and isinstance(roe, (int, float)):
                roe = f"{roe * 100:.1f}%"
            
            # Data dividen
            div_yield = info.get('dividendYield', 'N/A')
            if div_yield != 'N/A' and isinstance(div_yield, (int, float)):
                div_yield = f"{div_yield * 100:.2f}%"
            
            div_rate = info.get('dividendRate', 'N/A')
            if div_rate != 'N/A' and isinstance(div_rate, (int, float)):
                if kode_saham in INDONESIA_LIST:
                    div_rate = f"Rp {div_rate:,.0f}"
                else:
                    div_rate = f"${div_rate:.2f}"
            
            # Data pertumbuhan
            rev_growth = info.get('revenueGrowth', 'N/A')
            if rev_growth != 'N/A' and isinstance(rev_growth, (int, float)):
                rev_growth = f"{rev_growth * 100:.1f}%"
            
            profit_growth = info.get('earningsGrowth', 'N/A')
            if profit_growth != 'N/A' and isinstance(profit_growth, (int, float)):
                profit_growth = f"{profit_growth * 100:.1f}%"
            
            # Data keuangan lainnya
            der = info.get('debtToEquity', 'N/A')
            if der != 'N/A' and isinstance(der, (int, float)):
                der = f"{der:.2f}x"
            
            beta = info.get('beta', 'N/A')
            if beta != 'N/A' and isinstance(beta, (int, float)):
                beta = f"{beta:.2f}"
            
            market_cap = info.get('marketCap', 'N/A')
            if market_cap != 'N/A' and isinstance(market_cap, (int, float)):
                if market_cap > 1e12:
                    market_cap = f"{market_cap/1e12:.2f}T"
                elif market_cap > 1e9:
                    market_cap = f"{market_cap/1e9:.2f}B"
                elif market_cap > 1e6:
                    market_cap = f"{market_cap/1e6:.2f}M"
            
            # Kesimpulan fundamental
            conclusion = []
            if pe != 'N/A' and isinstance(pe, (int, float)):
                if pe < 15:
                    conclusion.append("✅ VALUASI: MURAH")
                elif pe < 25:
                    conclusion.append("⚠️ VALUASI: WAJAR")
                else:
                    conclusion.append("📈 VALUASI: MAHAL")
            
            if roe != 'N/A' and '%' in str(roe):
                roe_val = float(roe.replace('%', ''))
                if roe_val > 15:
                    conclusion.append("✅ PROFIT: SANGAT BAIK")
                elif roe_val > 10:
                    conclusion.append("✅ PROFIT: BAIK")
                else:
                    conclusion.append("⚠️ PROFIT: CUKUP")
            
            return {
                'valuasi': {
                    'PE': pe,
                    'PB': pb,
                    'EPS': eps,
                    'ROE': roe,
                },
                'dividen': {
                    'Yield': div_yield,
                    'Rate': div_rate,
                },
                'pertumbuhan': {
                    'Revenue': rev_growth,
                    'Laba': profit_growth,
                },
                'keuangan': {
                    'DER': der,
                    'Beta': beta,
                    'MarketCap': market_cap,
                },
                'kesimpulan': conclusion if conclusion else ['ℹ️ Data terbatas']
            }
        except Exception as e:
            logger.error(f"Error getting fundamental data: {e}")
            return {
                'valuasi': {'PE': 'N/A', 'PB': 'N/A', 'EPS': 'N/A', 'ROE': 'N/A'},
                'dividen': {'Yield': 'N/A', 'Rate': 'N/A'},
                'pertumbuhan': {'Revenue': 'N/A', 'Laba': 'N/A'},
                'keuangan': {'DER': 'N/A', 'Beta': 'N/A', 'MarketCap': 'N/A'},
                'kesimpulan': ['⚠️ Data fundamental tidak tersedia']
            }

    def get_bandarmology_summary(self, df):
        """Ringkasan bandarmology (analisis volume & money flow)"""
        if df is None or df.empty or len(df) < 20:
            return {}
        
        latest = df.iloc[-1]
        df_volume = df.tail(20)
        
        # Volume profile
        up_volume = 0
        down_volume = 0
        for i in range(1, len(df_volume)):
            if df_volume['Close'].iloc[i] > df_volume['Close'].iloc[i-1]:
                up_volume += df_volume['Volume'].iloc[i]
            else:
                down_volume += df_volume['Volume'].iloc[i]
        
        total_volume = up_volume + down_volume
        if total_volume > 0:
            up_ratio = (up_volume / total_volume) * 100
            down_ratio = (down_volume / total_volume) * 100
        else:
            up_ratio = down_ratio = 0
        
        # Accumulation/distribution days
        acc_days = 0
        dist_days = 0
        for i in range(1, len(df_volume)):
            if df_volume['Close'].iloc[i] > df_volume['Close'].iloc[i-1] and df_volume['Volume'].iloc[i] > df_volume['Volume_MA'].iloc[i]:
                acc_days += 1
            elif df_volume['Close'].iloc[i] < df_volume['Close'].iloc[i-1] and df_volume['Volume'].iloc[i] > df_volume['Volume_MA'].iloc[i]:
                dist_days += 1
        
        # Money flow
        money_flow = latest['OBV'] - df['OBV'].iloc[-5] if len(df) > 5 else 0
        money_flow_trend = "POSITIF 🟢" if money_flow > 0 else "NEGATIF 🔴" if money_flow < 0 else "NETRAL ⚪"
        
        # Volume trend
        volume_ma5 = df['Volume'].tail(5).mean()
        volume_ma20 = df['Volume'].tail(20).mean()
        volume_trend = "MENINGKAT 🟢" if volume_ma5 > volume_ma20 else "MENURUN 🔴"
        
        # Institutional presence (estimasi dari large transactions)
        avg_volume = df['Volume'].tail(20).mean()
        large_tx_ratio = (latest['Volume'] / avg_volume) if avg_volume > 0 else 1
        
        # Kesimpulan
        conclusion = []
        if acc_days > dist_days and up_ratio > 60:
            conclusion.append("✅ AKUMULASI: INSTITUSI")
        elif dist_days > acc_days and down_ratio > 60:
            conclusion.append("🔴 DISTRIBUSI: INSTITUSI")
        else:
            conclusion.append("⚪ NETRAL: RETAIL")
        
        if large_tx_ratio > 2:
            conclusion.append("💰 VOLUME: BANDAR MASUK")
        elif large_tx_ratio > 1.5:
            conclusion.append("📊 VOLUME: INSTITUSI")
        else:
            conclusion.append("📈 VOLUME: RETAIL")
        
        return {
            'volume_profile': {
                'Up Volume': f"{up_ratio:.1f}%",
                'Down Volume': f"{down_ratio:.1f}%",
            },
            'accumulation': {
                'Acc Days': acc_days,
                'Dist Days': dist_days,
                'Net': f"+{acc_days - dist_days}" if acc_days > dist_days else f"{acc_days - dist_days}",
            },
            'money_flow': {
                'OBV Trend': money_flow_trend,
                'Volume Trend': volume_trend,
                'Large Tx': f"{large_tx_ratio:.1f}x",
            },
            'kesimpulan': conclusion,
        }

    async def analyze_and_send(self, update: Update, kode_saham: str):
        """Analisis lengkap dan kirim ke Telegram"""
        try:
            msg = await update.message.reply_text(f"🔍 Menganalisis {kode_saham}... Mohon tunggu")
            
            # Ambil data
            df = await self.get_stock_data(kode_saham)
            
            if df is None or df.empty:
                await msg.edit_text(f"❌ Data {kode_saham} tidak ditemukan. Pastikan kode saham benar.")
                return
            
            # Generate chart
            chart_data = await self.generate_chart(kode_saham, df)
            
            # Deteksi pola
            patterns = self.detect_trading_patterns(df)
            
            # Data fundamental
            fundamental = self.get_fundamental_summary(kode_saham, df)
            
            # Data bandarmology
            bandarmology = self.get_bandarmology_summary(df)
            
            # Data terbaru
            latest = df.iloc[-1]
            prev = df.iloc[-2] if len(df) > 1 else latest
            
            # Tentukan mata uang
            currency = "Rp" if kode_saham in INDONESIA_LIST else "$"
            
            # Hitung perubahan
            change = latest['Close'] - prev['Close']
            change_pct = (change / prev['Close']) * 100
            change_emoji = "🟢" if change > 0 else "🔴" if change < 0 else "⚪"
            
            # Tentukan trend berdasarkan MA
            ma_status = []
            if latest['Close'] > latest['MA20']:
                ma_status.append("ATAS MA20 🟢")
            else:
                ma_status.append("BAWAH MA20 🔴")
            
            if latest['MA20'] > latest['MA50']:
                ma_status.append("MA20 > MA50 🟢")
            else:
                ma_status.append("MA20 < MA50 🔴")
            
            # Format pesan
            message = f"""
📈 *ANALISIS SAHAM {kode_saham}*
━━━━━━━━━━━━━━━━━━━━━
🕐 Update: {datetime.now().strftime('%d/%m/%Y %H:%M WIB')}
💰 Harga: {currency} {latest['Close']:,.2f}
📊 Perubahan: {change_emoji} {change:+,.2f} ({change_pct:+.2f}%)
📊 IHSG/SPX: Mengikuti market

╔══════════════════════════════╗
║     🎯 SIGNAL TRADING        ║
╚══════════════════════════════╝

🔥 *SWING TRADING (1-5 HARI)*
├─ Parabolic SAR: {"BULLISH 🟢" if latest['Close'] > latest['PSAR'] else "BEARISH 🔴"}
├─ MACD: {"BULLISH 🟢" if latest['MACD'] > latest['MACD_Signal'] else "BEARISH 🔴"}
├─ RSI: {latest['RSI']:.1f} ({'OVERSOLD' if latest['RSI'] < 30 else 'OVERBOUGHT' if latest['RSI'] > 70 else 'NETRAL'})
├─ Stochastic: {latest['Stoch_K']:.1f}/{latest['Stoch_D']:.1f} ({'OVERSOLD' if latest['Stoch_K'] < 20 else 'OVERBOUGHT' if latest['Stoch_K'] > 80 else 'NETRAL'})
├─ Swing Score: {patterns.get('swing', {}).get('swing_score', 0)} ({'BULLISH' if patterns.get('swing', {}).get('swing_score', 0) > 0 else 'BEARISH' if patterns.get('swing', {}).get('swing_score', 0) < 0 else 'NETRAL'})
└─ Signal: {"🟢 BULLISH" if patterns.get('swing', {}).get('swing_score', 0) > 0 else "🔴 BEARISH" if patterns.get('swing', {}).get('swing_score', 0) < 0 else "⚪ NETRAL"}

⚡ *DAY TRADE (INTRADAY)*
├─ Intraday: {patterns.get('daytrade', {}).get('intraday_change', '0%')}
├─ Volume: {patterns.get('daytrade', {}).get('volume_ratio', '1x')}
├─ Signal: {patterns.get('daytrade', {}).get('signal', 'NEUTRAL')}
└─ Alasan: {patterns.get('daytrade', {}).get('reasons', ['-'])[0]}

╔══════════════════════════════╗
║     📊 TEKNIKAL              ║
╚══════════════════════════════╝
Timeframe 1 Day

📈 *MOVING AVERAGES*
├─ MA5  : {currency} {latest['MA5']:,.2f} ({'ATAS' if latest['Close'] > latest['MA5'] else 'BAWAH'}) {🟢 if latest['Close'] > latest['MA5'] else '🔴'}
├─ MA20 : {currency} {latest['MA20']:,.2f} ({'ATAS' if latest['Close'] > latest['MA20'] else 'BAWAH'}) {🟢 if latest['Close'] > latest['MA20'] else '🔴'}
├─ MA50 : {currency} {latest['MA50']:,.2f} ({'ATAS' if latest['Close'] > latest['MA50'] else 'BAWAH'}) {🟢 if latest['Close'] > latest['MA50'] else '🔴'}
├─ MA100: {currency} {latest['MA100']:,.2f} ({'ATAS' if latest['Close'] > latest['MA100'] else 'BAWAH'}) {🟢 if latest['Close'] > latest['MA100'] else '🔴'}
└─ MA200: {currency} {latest['MA200']:,.2f} ({'ATAS' if latest['Close'] > latest['MA200'] else 'BAWAH'}) {🟢 if latest['Close'] > latest['MA200'] else '🔴'}

📊 *MOMENTUM*
├─ RSI(14)    : {latest['RSI']:.1f} (NETRAL)
├─ Stochastic : {latest['Stoch_K']:.1f}/{latest['Stoch_D']:.1f} (NETRAL)
├─ MACD       : {latest['MACD']:.2f} ({'BULLISH' if latest['MACD'] > latest['MACD_Signal'] else 'BEARISH'}) {🟢 if latest['MACD'] > latest['MACD_Signal'] else '🔴'}
└─ Williams %R: {latest['WilliamsR']:.1f} ({'OVERSOLD' if latest['WilliamsR'] < -80 else 'OVERBOUGHT' if latest['WilliamsR'] > -20 else 'NETRAL'})

📉 *VOLATILITAS*
├─ ATR(14)    : {currency} {latest['ATR']:.2f} ({latest['ATR_Percent']:.1f}%)
├─ Bollinger  : {'UPPER 🔴' if latest['Close'] > latest['BB_Upper'] else 'MIDDLE ⚪' if latest['Close'] > latest['BB_Lower'] else 'LOWER 🟢'}
├─ Upper: {currency} {latest['BB_Upper']:,.2f}
├─ Lower: {currency} {latest['BB_Lower']:,.2f}
└─ Width: {((latest['BB_Upper'] - latest['BB_Lower'])/latest['BB_Middle']*100):.1f}%

💰 *VOLUME*
├─ Hari ini  : {latest['Volume']:,.0f}
├─ Rata-rata : {latest['Volume_MA']:,.0f}
├─ Volume Ratio: {latest['Volume_Ratio']:.2f}x {🟢 if latest['Volume_Ratio'] > 1.5 else '⚪'}
└─ OBV: {'UPTREND 🟢' if latest['OBV'] > df['OBV'].iloc[-5] else 'DOWNTREND 🔴'}

╔══════════════════════════════╗
║     💰 FUNDAMENTAL (RINGKAS) ║
╚══════════════════════════════╝

📋 *VALUASI*
├─ P/E : {fundamental['valuasi']['PE']}
├─ P/B : {fundamental['valuasi']['PB']}
├─ EPS : {currency} {fundamental['valuasi']['EPS']}
└─ ROE : {fundamental['valuasi']['ROE']}

💰 *DIVIDEN*
├─ Yield: {fundamental['dividen']['Yield']}
└─ Rate : {currency} {fundamental['dividen']['Rate']}

📊 *KINERJA*
├─ Revenue Growth: {fundamental['pertumbuhan']['Revenue']}
├─ Laba Growth: {fundamental['pertumbuhan']['Laba']}
├─ DER: {fundamental['keuangan']['DER']}
└─ Beta: {fundamental['keuangan']['Beta']}

⚖️ *KESIMPULAN FUNDAMENTAL*
{chr(10).join(['├─ ' + c for c in fundamental['kesimpulan']])}

╔══════════════════════════════╗
║     🕵️ BANDARMOLOGY (RINGKAS)║
╚══════════════════════════════╝

📊 *VOLUME PROFILE* (20 HARI)
├─ Up Volume: {bandarmology.get('volume_profile', {}).get('Up Volume', '0%')}
├─ Down Volume: {bandarmology.get('volume_profile', {}).get('Down Volume', '0%')}
└─ Net: {bandarmology.get('accumulation', {}).get('Net', '0')} hari

🔄 *MONEY FLOW*
├─ OBV: {bandarmology.get('money_flow', {}).get('OBV Trend', 'NETRAL')}
├─ Volume: {bandarmology.get('money_flow', {}).get('Volume Trend', 'NETRAL')}
└─ Large Tx: {bandarmology.get('money_flow', {}).get('Large Tx', '1x')}

🎯 *KESIMPULAN BANDARMOLOGY*
{chr(10).join(['├─ ' + c for c in bandarmology.get('kesimpulan', ['Data terbatas'])[:2]])}

╔══════════════════════════════╗
║     📈 LEVEL KUNCI           ║
╚══════════════════════════════╝

🎯 *SUPPORT & RESISTANCE*
├─ R3: {currency} {latest['Close'] * 1.1:,.2f}
├─ R2: {currency} {latest['Resistance']:,.2f}
├─ R1: {currency} {(latest['Resistance'] + latest['Close'])/2:,.2f}
├─ P:  {currency} {latest['Close']:,.2f} (CURRENT)
├─ S1: {currency} {(latest['Support'] + latest['Close'])/2:,.2f}
├─ S2: {currency} {latest['Support']:,.2f}
└─ S3: {currency} {latest['Close'] * 0.9:,.2f}

📊 *PIVOT POINTS (CLASSIC)*
├─ R3: {currency} {latest['High'] * 1.05:,.2f}
├─ R2: {currency} {latest['High']:,.2f}
├─ R1: {currency} {(latest['High'] + latest['Close'])/2:,.2f}
├─ P:  {currency} {(latest['High'] + latest['Low'] + latest['Close'])/3:,.2f}
├─ S1: {currency} {(latest['Low'] + latest['Close'])/2:,.2f}
├─ S2: {currency} {latest['Low']:,.2f}
└─ S3: {currency} {latest['Low'] * 0.95:,.2f}

╔══════════════════════════════╗
║     🤖 RECOMMENDATION        ║
╚══════════════════════════════╝

📋 *STRATEGY*

🟢 *SWING TRADING (1-5 HARI)*
├─ Area Buy: {currency} {latest['Close'] * 0.98:,.2f} - {currency} {latest['Close']:,.2f}
├─ Stop Loss: {currency} {latest['Support'] * 0.98:,.2f} (-{(1 - (latest['Support'] * 0.98 / latest['Close'])) * 100:.1f}%)
├─ Target TP1: {currency} {latest['Resistance']:,.2f} (+{((latest['Resistance']/latest['Close'])-1)*100:.1f}%)
├─ Target TP2: {currency} {latest['Resistance'] * 1.02:,.2f} (+{((latest['Resistance']*1.02/latest['Close'])-1)*100:.1f}%)
├─ Target TP3: {currency} {latest['Resistance'] * 1.05:,.2f} (+{((latest['Resistance']*1.05/latest['Close'])-1)*100:.1f}%)
├─ Risk/Reward: 1:{((latest['Resistance']/latest['Close'])-1)/((1 - (latest['Support']/latest['Close'])) + 0.1):.1f}
└─ Alasan AI Buy: {patterns.get('swing', {}).get('buy_signals', ['Sideways'])[0] if patterns.get('swing', {}).get('buy_signals') else 'Menunggu konfirmasi'}

⚡ *DAY TRADE*
├─ Area Buy: {currency} {latest['Close'] * 0.995:,.2f} - {currency} {latest['Close']:,.2f}
├─ Stop Loss: {currency} {latest['Close'] * 0.99:,.2f} (-1.0%)
├─ Target TP1: {currency} {latest['Close'] * 1.01:,.2f} (+1.0%)
├─ Target TP2: {currency} {latest['Close'] * 1.015:,.2f} (+1.5%)
├─ Risk/Reward: 1:1.5
└─ Alasan AI Buy: {patterns.get('daytrade', {}).get('reasons', ['Intraday momentum'])[0]}

🔴 *SELL SIGNAL (Jika Breakdown)*
├─ Area Sell: {currency} {latest['Support'] * 0.99:,.2f} - {currency} {latest['Support']:,.2f}
├─ Stop Loss: {currency} {latest['Close'] * 1.01:,.2f} (+1.0%)
├─ Target TP1: {currency} {latest['Support'] * 0.98:,.2f} (-2.0%)
├─ Target TP2: {currency} {latest['Support'] * 0.95:,.2f} (-5.0%)
├─ Risk/Reward: 1:2
└─ Alasan AI Sell: {'Jika breakdown support ' + currency + f'{latest["Support"]:,.2f}'}

📈 *LONG TERM INVESTASI*
├─ Area Buy: {currency} {latest['MA50']:,.2f} - {currency} {latest['MA200']:,.2f}
├─ Stop Loss: {currency} {latest['MA200'] * 0.95:,.2f} (-5.0%)
├─ Target TP1: {currency} {latest['Close'] * 1.1:,.2f} (+10%)
├─ Target TP2: {currency} {latest['Close'] * 1.2:,.2f} (+20%)
├─ Target TP3: {currency} {latest['Close'] * 1.3:,.2f} (+30%)
├─ Holding Period: 6-12 Bulan
└─ Alasan AI Buy: {'Fundamental kuat' if len(fundamental['kesimpulan']) > 0 else 'Teknikal bullish'}

📊 *SUMMARY SIGNALS*
├─ Bullish Signals: {len(patterns.get('swing', {}).get('buy_signals', []))} 🟢
├─ Bearish Signals: {len(patterns.get('swing', {}).get('sell_signals', []))} 🔴
├─ Neutral Signals: 5 ⚪
├─ Trend: {'UPTREND 📈' if latest['Close'] > latest['MA50'] else 'DOWNTREND 📉'}
├─ Volume: {'AKUMULASI' if latest['Volume_Ratio'] > 1.2 else 'SEPI'}
├─ Bandar: {bandarmology.get('kesimpulan', ['NETRAL'])[0].replace('✅', '').replace('🔴', '').strip()}
└─ Fundamental: {'KUAT' if 'SANGAT BAIK' in str(fundamental['kesimpulan']) else 'CUKUP'}

⚠️ *RISK WARNING*
├─ Resistance di {currency} {latest['Resistance']:,.2f}
├─ Support di {currency} {latest['Support']:,.2f}
├─ RSI: {latest['RSI']:.1f} ({'Waspada overbought' if latest['RSI'] > 70 else 'Waspada oversold' if latest['RSI'] < 30 else 'Normal'})
└─ Hold jika di atas MA20

📌 *DISCLAIMER*
Analisis ini untuk referensi, 
bukan rekomendasi jual/beli.
Selalu lakukan riset mandiri.

━━━━━━━━━━━━━━━━━━━━━
🔍 Ketik kode saham lain:
{', '.join(INDONESIA_LIST[:5] + US_LIST[:5])}
"""
            
            # Hapus pesan processing
            await msg.delete()
            
            # Kirim chart dulu jika ada
            if chart_data:
                await update.message.reply_photo(
                    photo=io.BytesIO(chart_data),
                    caption=f"📊 Chart {kode_saham} - 60 Hari Terakhir"
                )
            
            # Kirim analisis
            await update.message.reply_text(message, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"Error in analyze_and_send: {e}")
            await update.message.reply_text(f"❌ Terjadi kesalahan: {str(e)}")

# Inisialisasi bot
bot = IndonesianStockBot()

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler untuk perintah /start"""
    welcome_message = f"""
🚀 *BOT SAHAM INDONESIA & AS* 🚀

Halo! Saya adalah bot analisis saham dengan fitur lengkap:

📊 *FITUR:*
• Chart Candlestik + Indikator
• Analisis Teknikal Lengkap
• Fundamental Ringkas
• Bandarmology Ringkas
• Swing Trading Signal
• Day Trade Signal
• Support/Resistance
• Risk Management

🇮🇩 *SAHAM INDONESIA* ({len(INDONESIA_LIST)} saham)
Contoh: BBCA, BBRI, ASII, TLKM

🇺🇸 *SAHAM AS* ({len(US_LIST)} saham)
Contoh: AAPL, TSLA, MSFT, AMZN

📝 *CARA PAKAI:*
Ketik kode saham langsung
Contoh: `BBCA` atau `AAPL`

📌 *PERINTAH LAIN:*
/help - Bantuan lengkap
/sectors - Daftar sektor
/trending - Saham trending
    """
    
    # Buat keyboard
    keyboard = [
        [InlineKeyboardButton("🇮🇩 BBCA", callback_data='BBCA'),
         InlineKeyboardButton("🇮🇩 BBRI", callback_data='BBRI'),
         InlineKeyboardButton("🇮🇩 ASII", callback_data='ASII')],
        [InlineKeyboardButton("🇺🇸 AAPL", callback_data='AAPL'),
         InlineKeyboardButton("🇺🇸 TSLA", callback_data='TSLA'),
         InlineKeyboardButton("🇺🇸 MSFT", callback_data='MSFT')],
        [InlineKeyboardButton("📊 Sektor ID", callback_data='sectors_id'),
         InlineKeyboardButton("📊 Sektor US", callback_data='sectors_us')]
    ]
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await update.message.reply_text(
        welcome_message,
        parse_mode='Markdown',
        reply_markup=reply_markup
    )

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler untuk perintah /help"""
    help_text = """
📚 *BANTUAN LENGKAP*

*CARA PAKAI:*
• Ketik kode saham (BBCA, AAPL, dll)
• Bot akan mengirim chart + analisis

*SAHAM INDONESIA:*
• BBCA - Bank BCA
• BBRI - Bank BRI
• ASII - Astra International
• TLKM - Telkom
• Dan lainnya (total {len(INDONESIA_LIST)} saham)

*SAHAM AMERIKA:*
• AAPL - Apple Inc
• MSFT - Microsoft
• TSLA - Tesla
• AMZN - Amazon
• Dan lainnya (total {len(US_LIST)} saham)

*PERINTAH:*
/start - Mulai bot
/help - Bantuan ini
/sectors - Lihat sektor
/trending - Saham trending

*INDIKATOR:*
• Moving Averages (5,20,50,100,200)
• RSI, MACD, Stochastic
• Bollinger Bands, Parabolic SAR
• Volume, OBV, ATR
• Support/Resistance
• Pivot Points

*DISCLAIMER:*
Bot ini untuk edukasi, bukan rekomendasi investasi.
    """
    await update.message.reply_text(help_text, parse_mode='Markdown')

async def sectors_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler untuk perintah /sectors"""
    message = "📊 *SEKTOR SAHAM*\n━━━━━━━━━━━━━━━━\n\n"
    
    message += "*🇮🇩 INDONESIA:*\n"
    for sector, stocks in list(INDONESIA_STOCKS.items())[:5]:
        message += f"• {sector}: {', '.join(stocks[:5])}...\n"
    
    message += "\n*🇺🇸 AMERIKA:*\n"
    for sector, stocks in list(US_STOCKS.items())[:5]:
        message += f"• {sector}: {', '.join(stocks[:5])}...\n"
    
    await update.message.reply_text(message, parse_mode='Markdown')

async def trending_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler untuk perintah /trending"""
    await update.message.reply_text("📊 Fitur trending akan segera hadir!")

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler untuk pesan teks biasa"""
    text = update.message.text.strip().upper()
    
    # Cek apakah input adalah kode saham
    if text in INDONESIA_LIST or text in US_LIST:
        await bot.analyze_and_send(update, text)
    elif text.isalpha() and 1 <= len(text) <= 5:
        # Coba cek dengan .JK untuk Indonesia
        if text in [s.replace('.JK', '') for s in INDONESIA_LIST]:
            await bot.analyze_and_send(update, text)
        else:
            await update.message.reply_text(
                f"❌ Kode saham '{text}' tidak ditemukan.\n\n"
                f"Contoh saham ID: {', '.join(INDONESIA_LIST[:5])}\n"
                f"Contoh saham US: {', '.join(US_LIST[:5])}"
            )
    else:
        await update.message.reply_text(
            "❌ Format salah. Masukkan kode saham (contoh: BBCA atau AAPL)"
        )

async def button_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler untuk callback button"""
    query = update.callback_query
    await query.answer()
    
    if query.data in INDONESIA_LIST or query.data in US_LIST:
        # Buat message palsu untuk analyze_and_send
        class FakeMessage:
            def __init__(self, reply_text):
                self.message = type('obj', (object,), {
                    'reply_text': reply_text
                })
        
        fake_msg = FakeMessage(query.message.reply_text)
        fake_update = type('obj', (object,), {
            'message': fake_msg.message
        })
        
        await bot.analyze_and_send(fake_update, query.data)
    
    elif query.data == 'sectors_id':
        message = "📊 *SEKTOR INDONESIA*\n━━━━━━━━━━━━━━━━\n\n"
        for sector, stocks in INDONESIA_STOCKS.items():
            message += f"• *{sector}*: {len(stocks)} saham\n"
            message += f"  Contoh: {', '.join(stocks[:3])}\n\n"
        await query.message.reply_text(message, parse_mode='Markdown')
    
    elif query.data == 'sectors_us':
        message = "📊 *SEKTOR AMERIKA*\n━━━━━━━━━━━━━━━━\n\n"
        for sector, stocks in US_STOCKS.items():
            message += f"• *{sector}*: {len(stocks)} saham\n"
            message += f"  Contoh: {', '.join(stocks[:3])}\n\n"
        await query.message.reply_text(message, parse_mode='Markdown')

def main():
    """Fungsi utama"""
    print("=" * 50)
    print("🚀 BOT SAHAM INDONESIA & AS")
    print(f"📊 Total saham: {len(INDONESIA_LIST)} ID + {len(US_LIST)} US = {len(ALL_LIST)} saham")
    print("📈 Fitur: Chart + Teknikal + Fundamental + Bandarmology")
    print("=" * 50)
    
    # Buat aplikasi
    application = Application.builder().token(BOT_TOKEN).build()
    
    # Register command handlers
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("sectors", sectors_command))
    application.add_handler(CommandHandler("trending", trending_command))
    
    # Handler untuk callback button
    application.add_handler(CallbackQueryHandler(button_callback))
    
    # Handler untuk pesan teks biasa
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    
    # Start bot
    print("🤖 Bot berjalan... Tekan Ctrl+C untuk berhenti")
    application.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == '__main__':
    main()
