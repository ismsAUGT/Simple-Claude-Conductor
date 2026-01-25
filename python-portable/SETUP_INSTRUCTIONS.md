# Setting Up Portable Python

This folder should contain a portable Python installation with Flask pre-installed.

## Quick Setup (One-Time)

### Step 1: Download Python Embeddable Package

1. Go to https://www.python.org/downloads/windows/
2. Find **Python 3.12.x** (or latest 3.12)
3. Download **Windows embeddable package (64-bit)** (the .zip file, ~10MB)
4. Extract the contents directly into this `python-portable/` folder

After extraction, you should see:
```
python-portable/
├── python.exe
├── pythonw.exe
├── python312.dll
├── python312.zip
├── python312._pth
├── ... (other .dll files)
└── SETUP_INSTRUCTIONS.md (this file)
```

### Step 2: Enable Site Packages

1. Open `python312._pth` in a text editor
2. Find the line that says `#import site`
3. Remove the `#` to uncomment it, so it reads: `import site`
4. Save the file

### Step 3: Install pip

1. Download https://bootstrap.pypa.io/get-pip.py
2. Save it to this `python-portable/` folder
3. Open a command prompt in this folder
4. Run: `python.exe get-pip.py`

### Step 4: Install Flask

Run these commands:
```cmd
python.exe -m pip install flask
python.exe -m pip install flask-cors
```

### Step 5: Verify Installation

Run this command to verify Flask is installed:
```cmd
python.exe -c "import flask; print(f'Flask {flask.__version__} installed successfully!')"
```

You should see: `Flask X.X.X installed successfully!`

## Folder Structure After Setup

```
python-portable/
├── python.exe
├── pythonw.exe
├── python312.dll
├── python312.zip
├── python312._pth (modified)
├── get-pip.py
├── Lib/
│   └── site-packages/
│       ├── flask/
│       ├── werkzeug/
│       ├── jinja2/
│       └── ... (other dependencies)
├── Scripts/
│   ├── pip.exe
│   └── flask.exe
└── SETUP_INSTRUCTIONS.md
```

## Troubleshooting

### "python.exe is not recognized"
Make sure you're running commands from inside the `python-portable/` folder.

### "No module named pip"
You need to run get-pip.py first. See Step 3.

### "No module named flask"
You need to install Flask. See Step 4.

### Antivirus Blocks Python
Some antivirus software may flag portable Python. You may need to add an exception for this folder.

## For Developers: Automating Setup

You can automate the setup with this batch script:

```batch
@echo off
cd /d "%~dp0"

echo Downloading get-pip.py...
curl -o get-pip.py https://bootstrap.pypa.io/get-pip.py

echo Installing pip...
python.exe get-pip.py

echo Installing Flask...
python.exe -m pip install flask flask-cors

echo.
echo Setup complete! Testing Flask import...
python.exe -c "import flask; print(f'Flask {flask.__version__} ready!')"
```

Save this as `setup.bat` and run it after extracting Python.
