#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import subprocess
import time
from pathlib import Path

class Colors:
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
        print(f"{color}{text}{self.colors.END}")
    
    def print_header(self, text):
        print(f"\n{self.colors.CYAN}{self.colors.BOLD}{'='*60}{self.colors.END}")
        print(f"{self.colors.CYAN}{self.colors.BOLD}🎯 {text}{self.colors.END}")
        print(f"{self.colors.CYAN}{self.colors.BOLD}{'='*60}{self.colors.END}")
    
    def print_success(self, text):
        print(f"{self.colors.GREEN}✅ {text}{self.colors.END}")
    
    def print_error(self, text):
        print(f"{self.colors.RED}❌ {text}{self.colors.END}")
    
    def print_warning(self, text):
        print(f"{self.colors.YELLOW}⚠️  {text}{self.colors.END}")
    
    def print_info(self, text):
        print(f"{self.colors.BLUE}🧋 {text}{self.colors.END}")
    
    def display_banner(self):
        banner = f"""
{self.colors.MAGENTA}{self.colors.BOLD}
╔══════════════════════════════════════════════╗
║                {self.colors.CYAN}ME-CLI MANAGER{self.colors.MAGENTA}                 ║
║           {self.colors.YELLOW}Auto Install & Update Tool{self.colors.MAGENTA}          ║
╚══════════════════════════════════════════════╝
{self.colors.END}"""
        print(banner)
        
        info = f"""
{self.colors.YELLOW}{self.colors.BOLD}⚠️  PERINGATAN PENTING ⚠️{self.colors.END}
{self.colors.RED}JANGAN SKIP SATU COMMAND PUN!{self.colors.END}
{self.colors.CYAN}Banyak yang sok paham & skip command, akhirnya stuck!{self.colors.END}
"""
        print(info)

    def check_installation_status(self):
        status = {
            'installed': False,
            'env_setup': False,
            'ready_to_run': False
        }
        
        if self.install_dir.exists():
            status['installed'] = True
            if self.env_file.exists():
                status['env_setup'] = True
            if (self.install_dir / self.script_name).exists():
                status['ready_to_run'] = True
                
        return status
    
    def get_status_icon(self, condition):
        if condition:
            return f"{self.colors.GREEN}✅{self.colors.END}"
        else:
            return f"{self.colors.RED}❌{self.colors.END}"
    
    def get_status_text(self, condition, true_text="Aktif", false_text="Tidak Aktif"):
        if condition:
            return f"{self.colors.GREEN}{true_text}{self.colors.END}"
        else:
            return f"{self.colors.RED}{false_text}{self.colors.END}"
    
    def show_menu(self):
        status = self.check_installation_status()
        
        menu = f"""
{self.colors.BOLD}{self.colors.CYAN}📋 PILIH MENU:{self.colors.END}

{self.colors.WHITE}1. 📥 {self.colors.BOLD}INSTALL ME-CLI{self.colors.END}       {self.get_status_icon(status['installed'])} {self.get_status_text(status['installed'], 'Terinstall', 'Belum Install')}
{self.colors.WHITE}2. 🔄 {self.colors.BOLD}UPDATE ME-CLI{self.colors.END}        {self.get_status_icon(status['installed'])} {self.get_status_text(status['installed'], 'Bisa Update', 'Install Dulu')}
{self.colors.WHITE}3. 🚀 {self.colors.BOLD}JALANKAN ME-CLI{self.colors.END}      {self.get_status_icon(status['ready_to_run'])} {self.get_status_text(status['ready_to_run'], 'Siap Jalankan', 'Belum Siap')}
{self.colors.WHITE}4. ⚙️  {self.colors.BOLD}SETUP ENVIRONMENT{self.colors.END}   {self.get_status_icon(status['env_setup'])} {self.get_status_text(status['env_setup'], 'Sudah Setup', 'Perlu Setup')}
{self.colors.WHITE}5. ℹ️  {self.colors.BOLD}INFO & TROUBLESHOOT{self.colors.END}
{self.colors.WHITE}*. ❌ {self.colors.BOLD}EXIT{self.colors.END}

{self.colors.BOLD}🎯 STATUS:{self.colors.END} {self.get_overall_status(status)}

{self.colors.YELLOW}Masukkan pilihan (1-6): {self.colors.END}"""
        return input(menu)
    
    def get_overall_status(self, status):
        if status['ready_to_run'] and status['env_setup']:
            return f"{self.colors.GREEN}{self.colors.BOLD}🟢 READY TO RUN{self.colors.END}"
        elif status['installed']:
            return f"{self.colors.YELLOW}{self.colors.BOLD}🟡 INSTALLED (But needs setup){self.colors.END}"
        else:
            return f"{self.colors.RED}{self.colors.BOLD}🔴 NOT INSTALLED{self.colors.END}"

    def run_command_manual(self, command, description):
        """Jalankan command dengan output manual"""
        self.print_info(description)
        print(f"{self.colors.CYAN}Command: {self.colors.YELLOW}{command}{self.colors.END}")
        print(f"{self.colors.CYAN}{'-'*50}{self.colors.END}")
        
        try:
            # Jalankan command dan tampilkan output real-time
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Tampilkan output real-time
            for line in process.stdout:
                print(f"{self.colors.WHITE}{line}{self.colors.END}", end='', flush=True)
            
            process.wait()
            
            if process.returncode == 0:
                self.print_success(f"Berhasil: {description}")
                return True
            else:
                self.print_error(f"Gagal: {description}")
                return False
                
        except Exception as e:
            self.print_error(f"Error: {e}")
            return False

    def install_me_cli(self):
        self.print_header("PROSES INSTALASI ME-CLI - JANGAN SKIP SATU PUN!")
        
        # Konfirmasi user
        print(f"{self.colors.RED}{self.colors.BOLD}⚠️  PASTIKAN KONEKSI INTERNET STABIL!{self.colors.END}")
        print(f"{self.colors.YELLOW}Proses ini akan menjalankan SEMUA command wajib:{self.colors.END}")
        
        commands = [
            "apt update && apt full-upgrade -y",
            "pkg install git -y", 
            "pkg install python -y",
            "apt install python-pillow -y",
            f"git clone {self.repo_url}",
            "cd me-cli && pip install -r requirements.txt",
            "cd me-cli && python main.py --test"
        ]
        
        for i, cmd in enumerate(commands, 1):
            print(f"{self.colors.CYAN}{i}. {cmd}{self.colors.END}")
        
        confirm = input(f"\n{self.colors.YELLOW}Lanjutkan instalasi? (y/N): {self.colors.END}")
        if confirm.lower() != 'y':
            self.print_warning("Instalasi dibatalkan!")
            input(f"{self.colors.YELLOW}Tekan Enter untuk kembali...{self.colors.END}")
            return
        
        try:
            # 1. UPDATE SYSTEM
            self.print_header("1. UPDATE SYSTEM")
            if not self.run_command_manual(
                "apt update && apt full-upgrade -y",
                "Update system packages (Wajib!)"
            ):
                self.print_error("GAGAL update system! Coba jalankan manual:")
                print(f"{self.colors.YELLOW}apt update && apt full-upgrade{self.colors.END}")
                return
            
            # 2. INSTALL GIT
            self.print_header("2. INSTALL GIT")
            if not self.run_command_manual(
                "pkg install git -y", 
                "Install Git (Wajib!)"
            ):
                self.print_error("GAGAL install Git!")
                return
            
            # 3. INSTALL PYTHON
            self.print_header("3. INSTALL PYTHON") 
            if not self.run_command_manual(
                "pkg install python -y",
                "Install Python (Wajib!)"
            ):
                self.print_error("GAGAL install Python!")
                return
            
            # 4. INSTALL PILLOW
            self.print_header("4. INSTALL PILLOW")
            if not self.run_command_manual(
                "apt install python-pillow -y",
                "Install Python Pillow (Wajib!)"
            ):
                self.print_warning("Pillow mungkin sudah terinstall, lanjutkan...")
            
            # 5. CLONE REPOSITORY
            self.print_header("5. CLONE REPOSITORY")
            if self.install_dir.exists():
                self.print_warning("Folder me-cli sudah ada, menghapus...")
                os.system("rm -rf me-cli")
            
            if not self.run_command_manual(
                f"git clone {self.repo_url}",
                "Clone repository me-cli (Wajib!)"
            ):
                self.print_error("GAGAL clone repository!")
                return
            
            # 6. INSTALL REQUIREMENTS
            self.print_header("6. INSTALL PYTHON REQUIREMENTS")
            if not self.run_command_manual(
                "cd me-cli && pip install -r requirements.txt",
                "Install semua dependencies Python (Wajib!)"
            ):
                self.print_error("GAGAL install requirements!")
                self.print_info("Coba manual: cd me-cli && pip install -r requirements.txt")
                return
            
            # 7. TEST JALANKAN SCRIPT
            self.print_header("7. TEST JALANKAN SCRIPT")
            self.print_info("Testing apakah script bisa jalan...")
            
            # Cek apakah main.py ada
            if (self.install_dir / "main.py").exists():
                self.print_success("main.py ditemukan!")
                
                # Try to run with --help or --version
                result = subprocess.run(
                    ["cd me-cli && python main.py --help"],
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                if result.returncode == 0:
                    self.print_success("Script berhasil dijalankan!")
                    print(f"{self.colors.WHITE}{result.stdout}{self.colors.END}")
                else:
                    self.print_warning("Script mungkin butuh environment variables")
                    print(f"{self.colors.YELLOW}Lanjutkan ke setup environment...{self.colors.END}")
            else:
                self.print_error("main.py tidak ditemukan!")
                return
            
            # FINAL SUCCESS
            self.print_header("🎉 INSTALASI BERHASIL!")
            self.print_success("Semua command wajib telah dijalankan!")
            
            print(f"\n{self.colors.BOLD}📋 Langkah selanjutnya:{self.colors.END}")
            print(f"{self.colors.GREEN}1. Setup Environment Variables (Menu 4) - WAJIB!{self.colors.END}")
            print(f"{self.colors.GREEN}2. Jalankan me-cli (Menu 3){self.colors.END}")
            
            print(f"\n{self.colors.BOLD}📍 Lokasi:{self.colors.END}")
            print(f"{self.colors.CYAN}{self.install_dir.absolute()}{self.colors.END}")
            
        except Exception as e:
            self.print_error(f"Error: {e}")
            self.print_info("Jika ada error, screenshot dan tanyakan di grup!")
        
        input(f"\n{self.colors.YELLOW}Tekan Enter untuk kembali ke menu...{self.colors.END}")

    def update_me_cli(self):
        self.print_header("UPDATE ME-CLI")
        
        if not self.install_dir.exists():
            self.print_error("me-cli belum terinstall!")
            return
        
        commands = [
            "cd me-cli && git pull --rebase",
            "cd me-cli && pip install -r requirements.txt"
        ]
        
        for cmd in commands:
            if not self.run_command_manual(cmd, f"Update: {cmd}"):
                self.print_error("Update gagal!")
                return
        
        self.print_success("Update berhasil!")

    def setup_environment(self):
        self.print_header("SETUP ENVIRONMENT VARIABLES")
        
        if not self.install_dir.exists():
            self.print_error("Install dulu!")
            return
        
        self.print_info("1. Buka: https://rentry.co/me-cli")
        self.print_info("2. Copy semua text")
        self.print_info("3. Buat file .env di folder me-cli")
        
        input(f"{self.colors.YELLOW}Tekan Enter setelah buka link...{self.colors.END}")
        os.system("termux-open-url https://rentry.co/me-cli")
        
        self.print_info("Buat file .env:")
        print(f"{self.colors.YELLOW}nano me-cli/.env{self.colors.END}")
        print(f"{self.colors.YELLOW}# Paste content dari rentry.co{self.colors.END}")
        print(f"{self.colors.YELLOW}# Ctrl+X → Y → Enter{self.colors.END}")
        
        input(f"{self.colors.YELLOW}Tekan Enter setelah setup...{self.colors.END}")

    def run_me_cli(self):
        self.print_header("JALANKAN ME-CLI")
        
        if not self.install_dir.exists():
            self.print_error("Install dulu!")
            return
        
        self.print_info("Menjalankan me-cli...")
        os.system("cd me-cli && python main.py")

    def script_info(self):
        self.print_header("INFO & TROUBLESHOOT")
        
        print(f"""
{self.colors.BOLD}🧋 FIRST TIME INSTALL (WAJIB URUT):{self.colors.END}
{self.colors.CYAN}1. apt update && apt full-upgrade{self.colors.END}
{self.colors.CYAN}2. pkg install git{self.colors.END}  
{self.colors.CYAN}3. pkg install python{self.colors.END}
{self.colors.CYAN}4. apt install python-pillow{self.colors.END}
{self.colors.CYAN}5. git clone https://github.com/purplemashu/me-cli{self.colors.END}
{self.colors.CYAN}6. cd me-cli && pip install -r requirements.txt{self.colors.END}
{self.colors.CYAN}7. python main.py{self.colors.END}

{self.colors.RED}🚫 JANGAN SKIP SATU COMMAND PUN!{self.colors.END}
{self.colors.YELLOW}Banyak yang sok paham & skip command, akhirnya stuck!{self.colors.END}
""")

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
                    input(f"\n{self.colors.YELLOW}Tekan Enter...{self.colors.END}")
                elif choice == '6':
                    self.print_success("Goodbye! 👋")
                    break
                else:
                    self.print_error("Pilihan salah!")
                    time.sleep(1)
                    
        except KeyboardInterrupt:
            self.print_error("\nDihentikan!")
            sys.exit(0)

if __name__ == "__main__":
    manager = MeCLIManager()
    manager.main()
