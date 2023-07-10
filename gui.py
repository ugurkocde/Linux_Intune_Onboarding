#!/usr/bin/env python3
import os
import subprocess
import tkinter as tk
from tkinter import messagebox, filedialog
from tkinter import ttk
from datetime import datetime
from functools import partial


LOG_FILE = "/var/log/linux2intune.log"

def append_log(log_file, message):
    with open(log_file, "a") as file:
        file.write(f"{datetime.now()}: {message}\n")

def execute_command(command):
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = process.communicate()

    if process.returncode != 0:
        messagebox.showerror('Error', error.decode("utf-8").strip())
        return None

    return output.decode("utf-8").strip()

def is_installed(package_name):
    return execute_command(f"dpkg -s {package_name}") is not None

def main_window(root):
    root.geometry("400x200")
    root.title("Linux2Intune")
    frame = tk.Frame(root)
    frame.pack()

    options = [
        "Microsoft Intune",
        "Defender for Endpoint",
        "Update and Upgrade System",
        "Show System Information"
    ]

    label = tk.Label(frame, text="Select an option:")
    label.pack()

    option_var = tk.StringVar()
    option_menu = ttk.Combobox(frame, textvariable=option_var, values=options)
    option_menu.pack()

    submit_button = tk.Button(frame, text="Submit", command=partial(submit, root, option_var))
    submit_button.pack()


def submit(root, option_var):
    option = option_var.get()

    if option == "Microsoft Intune":
        microsoft_intune(root)
    elif option == "Defender for Endpoint":
        defender_for_endpoint(root)
    elif option == "Update and Upgrade System":
        update_and_upgrade_system(root)
    elif option == "Show System Information":
        show_system_info(root)


def microsoft_intune(root):
    root.geometry("400x200")
    root.title("Microsoft Intune")
    frame = tk.Frame(root)
    frame.pack()

    options = [
        "Intune - Onboarding",
        "Intune - Offboarding",
        "Intune - Update App",
        "Back to Main Menu"
    ]

    label = tk.Label(frame, text="Select an option:")
    label.pack()

    option_var = tk.StringVar()
    option_menu = ttk.Combobox(frame, textvariable=option_var, values=options)
    option_menu.pack()

    submit_button = tk.Button(frame, text="Submit", command=partial(intune_submit, root, option_var))
    submit_button.pack()


# Similar function for `defender_for_endpoint` and `update_and_upgrade_system` 
# can be written using same logic as `microsoft_intune`

def show_system_info(root):
    command = "/bin/sh -c 'uname -a; echo; free -h; echo; df -h; echo; lscpu; echo; ip a'"
    execute_command(command)


def intune_submit(root, option_var):
    option = option_var.get()

    if option == "Intune - Onboarding":
        intune_onboarding(root)
    elif option == "Intune - Offboarding":
        intune_offboarding(root)
    elif option == "Intune - Update App":
        intune_update_app(root)
    elif option == "Back to Main Menu":
        root.destroy()
        root = tk.Tk()
        main_window(root)
        root.mainloop()


# Similar functions for `intune_offboarding`, `intune_update_app`, `defender_for_endpoint_submit`, 
# and so on can be written using same logic as `intune_onboarding`

def intune_onboarding(root):
    command = "sudo apt install curl gpg -y"
    execute_command(command)

    # ... Rest of the commands for onboarding ...


if __name__ == "__main__":
    root = tk.Tk()
    main_window(root)
    root.mainloop()
