#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import subprocess
import time
import requests
from pathlib import Path

class Colors:
    # Color codes
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

class MeCLIManager:
    def __init__(self):
        self.script_name = "main.py"
        self.repo_url = "https://github.com/purplemashu/me-cli"
        self.install_dir = Path("me-cli")
        self.env_file = self.install_dir / ".env"
        self.colors = Colors()
        
    def clear_screen(self):
        os.system('cls' if os.name == 'nt' else 'clear')
    
    def print_color(self, text, color):
        """Print text dengan warna"""
        print(f"{color}{text}{self.colors.END}")
    
    def print_header(self, text):
        """Print header dengan style"""
        print(f"\n{self.colors.CYAN}{self.colors.BOLD}{'='*60}{self.colors.END}")
        print(f"{self.colors.CYAN}{self.colors.BOLD}🎯 {text}{self.colors.END}")
        print(f"{self.colors.CYAN}{self.colors.BOLD}{'='*60}{self.colors.END}")
    
    def print_success(self, text):
        """Print success message"""
        print(f"{self.colors.GREEN}✅ {text}{self.colors.END}")
    
    def print_error(self, text):
        """Print error message"""
        print(f"{self.colors.RED}❌ {text}{self.colors.END}")
    
    def print_warning(self, text):
        """Print warning message"""
        print(f"{self.colors.YELLOW}⚠️  {text}{self.colors.END}")
    
    def print_info(self, text):
        """Print info message"""
        print(f"{self.colors.BLUE}🧋 {text}{self.colors.END}")
    
    def display_banner(self):
        """Display colorful banner"""
        banner = f"""
{self.colors.MAGENTA}{self.colors.BOLD}
╔══════════════════════════════════════════════╗
║                {self.colors.CYAN}ME-CLI MANAGER{self.colors.MAGENTA}                 ║
║           {self.colors.YELLOW}Auto Install & Update Tool{self.colors.MAGENTA}          ║
╚══════════════════════════════════════════════╝
{self.colors.END}"""
        print(banner)
        
        info = f"""
{self.colors.YELLOW}{self.colors.BOLD}⚠️  INFORMATION �️{self.colors.END}
{self.colors.CYAN}🧋 Repository: {self.colors.WHITE}https://github.com/purplemashu/me-cli{self.colors.END}
{self.colors.CYAN}🧋 Pastikan jalankan semua command dengan benar!{self.colors.END}
"""
        print(info)
    
    def check_installation_status(self):
        """Cek status instalasi"""
        status = {
            'installed': False,
            'env_setup': False,
            'ready_to_run': False
        }
        
        # Cek apakah directory me-cli ada
        if self.install_dir.exists():
            status['installed'] = True
            
            # Cek apakah file .env ada
            if self.env_file.exists():
                status['env_setup'] = True
                
            # Cek apakah main.py ada
            if (self.install_dir / self.script_name).exists():
                status['ready_to_run'] = True
                
        return status
    
    def get_status_icon(self, condition):
        """Dapatkan icon status dengan warna"""
        if condition:
            return f"{self.colors.GREEN}✅{self.colors.END}"
        else:
            return f"{self.colors.RED}❌{self.colors.END}"
    
    def get_status_text(self, condition, true_text="Aktif", false_text="Tidak Aktif"):
        """Dapatkan text status dengan warna"""
        if condition:
            return f"{self.colors.GREEN}{true_text}{self.colors.END}"
        else:
            return f"{self.colors.RED}{false_text}{self.colors.END}"
    
    def show_menu(self):
        """Tampilkan menu dengan status berwarna"""
        status = self.check_installation_status()
        
        menu = f"""
{self.colors.BOLD}{self.colors.CYAN}📋 PILIH MENU:{self.colors.END}

{self.colors.WHITE}1. 📥 {self.colors.BOLD}INSTALL ME-CLI{self.colors.END}       {self.get_status_icon(status['installed'])} {self.get_status_text(status['installed'], 'Terinstall', 'Belum Install')}
{self.colors.WHITE}2. 🔄 {self.colors.BOLD}UPDATE ME-CLI{self.colors.END}        {self.get_status_icon(status['installed'])} {self.get_status_text(status['installed'], 'Bisa Update', 'Install Dulu')}
{self.colors.WHITE}3. 🚀 {self.colors.BOLD}JALANKAN ME-CLI{self.colors.END}      {self.get_status_icon(status['ready_to_run'])} {self.get_status_text(status['ready_to_run'], 'Siap Jalankan', 'Belum Siap')}
{self.colors.WHITE}4. ⚙️  {self.colors.BOLD}SETUP ENVIRONMENT{self.colors.END}   {self.get_status_icon(status['env_setup'])} {self.get_status_text(status['env_setup'], 'Sudah Setup', 'Perlu Setup')}
{self.colors.WHITE}5. ℹ️  {self.colors.BOLD}INFO & TROUBLESHOOT{self.colors.END}
{self.colors.WHITE}6. ❌ {self.colors.BOLD}KELUAR{self.colors.END}

{self.colors.BOLD}🎯 STATUS:{self.colors.END} {self.get_overall_status(status)}

{self.colors.YELLOW}Masukkan pilihan (1-6): {self.colors.END}"""
        return input(menu)
    
    def get_overall_status(self, status):
        """Dapatkan status overall dengan warna"""
        if status['ready_to_run'] and status['env_setup']:
            return f"{self.colors.GREEN}{self.colors.BOLD}🟢 READY TO RUN{self.colors.END}"
        elif status['installed']:
            return f"{self.colors.YELLOW}{self.colors.BOLD}🟡 INSTALLED (But needs setup){self.colors.END}"
        else:
            return f"{self.colors.RED}{self.colors.BOLD}🔴 NOT INSTALLED{self.colors.END}"
    
    def show_detailed_status(self):
        """Tampilkan status detail dengan warna"""
        status = self.check_installation_status()
        
        self.print_header("DETAILED STATUS")
        
        print(f"{self.colors.WHITE}1. Repository cloned:    {self.get_status_icon(status['installed'])} {self.get_status_text(status['installed'])}")
        print(f"2. Environment setup:    {self.get_status_icon(status['env_setup'])} {self.get_status_text(status['env_setup'])}")
        print(f"3. Main script ready:    {self.get_status_icon(status['ready_to_run'])} {self.get_status_text(status['ready_to_run'])}")
        
        if status['installed']:
            print(f"\n{self.colors.CYAN}📁 Lokasi: {self.colors.WHITE}{self.install_dir.absolute()}{self.colors.END}")
        
        print(f"\n{self.colors.BOLD}🎯 Overall Status: {self.get_overall_status(status)}{self.colors.END}")
    
    def run_command(self, command, description=""):
        """Jalankan command dan tampilkan output dengan warna"""
        if description:
            self.print_info(f"{description}")
            print(f"{self.colors.CYAN}{'-'*40}{self.colors.END}")
        
        try:
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True
            )
            
            # Tampilkan output real-time
            for line in process.stdout:
                print(f"{self.colors.WHITE}{line}{self.colors.END}", end='')
                
            process.wait()
            return process.returncode == 0
            
        except Exception as e:
            self.print_error(f"Command error: {e}")
            return False
    
    def install_me_cli(self):
        self.print_header("PROSES INSTALASI ME-CLI")
        
        try:
            # Cek apakah sudah terinstall
            if self.install_dir.exists():
                self.print_warning("me-cli sudah terinstall!")
                self.print_info("Gunakan menu UPDATE untuk memperbarui.")
                input(f"\n{self.colors.YELLOW}Tekan Enter untuk kembali ke menu...{self.colors.END}")
                return
            
            self.print_info("First Time Setup (WAJIB)...")
            time.sleep(1)
            
            # 1. Update system
            if not self.run_command("apt update && apt full-upgrade -y", "Update system packages"):
                self.print_error("Gagal update system!")
                return
            
            # 2. Install dependencies
            dependencies = [
                ("pkg install git -y", "Install Git"),
                ("pkg install python -y", "Install Python"),
                ("apt install python-pillow -y", "Install Python Pillow")
            ]
            
            for cmd, desc in dependencies:
                if not self.run_command(cmd, desc):
                    self.print_error(f"Gagal {desc.lower()}")
                    return
            
            # 3. Clone repository
            if not self.run_command(f"git clone {self.repo_url}", "Clone repository me-cli"):
                self.print_error("Gagal clone repository!")
                return
            
            # 4. Install Python requirements
            os.chdir(self.install_dir)
            if not self.run_command("pip install -r requirements.txt", "Install Python requirements"):
                self.print_error("Gagal install requirements!")
                return
            
            os.chdir("..")
            
            self.print_header("INSTALASI BERHASIL!")
            self.print_success("me-cli berhasil diinstall!")
            self.print_info("Langkah selanjutnya:")
            print(f"{self.colors.CYAN}1. Setup Environment Variables (Menu 4){self.colors.END}")
            print(f"{self.colors.CYAN}2. Jalankan me-cli (Menu 3){self.colors.END}")
            
        except Exception as e:
            self.print_error(f"Error saat install: {e}")
        
        input(f"\n{self.colors.YELLOW}Tekan Enter untuk kembali ke menu...{self.colors.END}")
    
    def update_me_cli(self):
        self.print_header("PROSES UPDATE ME-CLI")
        
        try:
            if not self.install_dir.exists():
                self.print_error("me-cli belum terinstall!")
                self.print_info("Silakan install terlebih dahulu.")
                input(f"\n{self.colors.YELLOW}Tekan Enter untuk kembali ke menu...{self.colors.END}")
                return
            
            self.print_info("Update Process...")
            
            # Masuk ke directory me-cli
            os.chdir(self.install_dir)
            
            # 1. Git pull update
            if not self.run_command("git pull --rebase", "Pull update dari GitHub"):
                self.print_error("Gagal pull update!")
                return
            
            # 2. Update requirements
            if not self.run_command("pip install -r requirements.txt", "Update Python requirements"):
                self.print_error("Gagal update requirements!")
                return
            
            os.chdir("..")
            
            self.print_success("UPDATE BERHASIL!")
            
        except Exception as e:
            self.print_error(f"Error saat update: {e}")
        
        input(f"\n{self.colors.YELLOW}Tekan Enter untuk kembali ke menu...{self.colors.END}")
    
    def setup_environment(self):
        self.print_header("SETUP ENVIRONMENT VARIABLES")
        
        try:
            if not self.install_dir.exists():
                self.print_error("me-cli belum terinstall!")
                self.print_info("Silakan install terlebih dahulu.")
                input(f"\n{self.colors.YELLOW}Tekan Enter untuk kembali ke menu...{self.colors.END}")
                return
            
            self.print_info("Menambahkan Environment Variables:")
            print(f"{self.colors.WHITE}1. Buka {self.colors.CYAN}https://rentry.co/me-cli{self.colors.WHITE} & copy contentnya{self.colors.END}")
            print(f"{self.colors.WHITE}2. Bikin file .env di dalam folder me-cli{self.colors.END}")
            
            input(f"\n{self.colors.YELLOW}Tekan Enter untuk membuka browser...{self.colors.END}")
            
            # Coba buka browser (untuk termux bisa pakai termux-open-url)
            self.run_command(f"termux-open-url https://rentry.co/me-cli", "Membuka rentry.co")
            
            self.print_info("Langkah manual:")
            print(f"{self.colors.WHITE}nano .env{self.colors.END}")
            print(f"{self.colors.WHITE}paste content{self.colors.END}")
            print(f"{self.colors.WHITE}ctrl+x → y → enter{self.colors.END}")
            
        except Exception as e:
            self.print_error(f"Error saat setup environment: {e}")
        
        input(f"\n{self.colors.YELLOW}Tekan Enter untuk kembali ke menu...{self.colors.END}")
    
    def run_me_cli(self):
        self.print_header("MENJALANKAN ME-CLI")
        
        try:
            script_file = self.install_dir / self.script_name
            
            if not script_file.exists():
                self.print_error("me-cli belum terinstall!")
                self.print_info("Silakan install terlebih dahulu.")
                input(f"\n{self.colors.YELLOW}Tekan Enter untuk kembali ke menu...{self.colors.END}")
                return
            
            self.print_info("Menjalankan me-cli...")
            print(f"{self.colors.CYAN}{'-'*30}{self.colors.END}")
            
            # Jalankan script
            os.chdir(self.install_dir)
            result = subprocess.run([sys.executable, self.script_name], 
                                  capture_output=True, text=True)
            
            print(f"{self.colors.WHITE}{result.stdout}{self.colors.END}")
            if result.stderr:
                print(f"{self.colors.RED}Error: {result.stderr}{self.colors.END}")
                
            os.chdir("..")
                
        except Exception as e:
            self.print_error(f"Error menjalankan me-cli: {e}")
        
        input(f"\n{self.colors.YELLOW}Tekan Enter untuk kembali ke menu...{self.colors.END}")
    
    def script_info(self):
        self.print_header("INFORMASI & TROUBLESHOOT")
        
        status = self.check_installation_status()
        
        print(f"{self.colors.BOLD}📊 Current Status:{self.colors.END}")
        self.show_detailed_status()
        
        print(f"\n{self.colors.BOLD}🔧 Troubleshoot Guide:{self.colors.END}")
        print(f"{self.colors.CYAN}❌ Environment variable error:{self.colors.END}")
        print(f"{self.colors.WHITE}   - Pastikan file .env sudah dibuat{self.colors.END}")
        print(f"{self.colors.WHITE}   - Content dari: {self.colors.UNDERLINE}https://rentry.co/me-cli{self.colors.END}")
        
        print(f"\n{self.colors.CYAN}❌ Module not found:{self.colors.END}")
        print(f"{self.colors.WHITE}   - Jalankan: {self.colors.YELLOW}pip install -r requirements.txt{self.colors.END}")
        
        print(f"\n{self.colors.CYAN}❌ Git error:{self.colors.END}")
        print(f"{self.colors.WHITE}   - Pastikan terhubung internet{self.colors.END}")
        print(f"{self.colors.WHITE}   - Coba: {self.colors.YELLOW}git pull --rebase{self.colors.END}")
    
    def main(self):
        try:
            while True:
                self.clear_screen()
                self.display_banner()
                
                choice = self.show_menu()
                
                if choice == '1':
                    self.install_me_cli()
                elif choice == '2':
                    self.update_me_cli()
                elif choice == '3':
                    self.run_me_cli()
                elif choice == '4':
                    self.setup_environment()
                elif choice == '5':
                    self.script_info()
                    input(f"\n{self.colors.YELLOW}Tekan Enter untuk kembali ke menu...{self.colors.END}")
                elif choice == '6':
                    self.print_success("Terima kasih telah menggunakan me-cli manager!")
                    self.print_info("Sampai jumpa lagi! 🚀")
                    break
                else:
                    self.print_error("Pilihan tidak valid! Silakan pilih 1-6.")
                    time.sleep(2)
                    
        except KeyboardInterrupt:
            self.print_error("\n\nProgram dihentikan oleh user")
            sys.exit(0)

if __name__ == "__main__":
    try:
        manager = MeCLIManager()
        manager.main()
    except Exception as e:
        print(f"{Colors.RED}❌ Error: {e}{Colors.END}")
        sys.exit(1)
