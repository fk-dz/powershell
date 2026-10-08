<p align="center"><img src="docs/logo.svg" width="110" alt="FATYAK"></p>

# FATYAK Shell

Run **Python, JavaScript, TypeScript, Java, Go, PHP, C and C++** from one PowerShell window. Free, local, **no API**, nothing to install.
Developer: **FATYAK**

## Features
- Each runtime is a portable ZIP downloaded once to `%LOCALAPPDATA%\FATYAK` (no installer, no PATH or registry changes)
- Python 3.12, Node.js 22, Deno (TypeScript), Java 21, Go 1.23, PHP 8.3, C and C++ (via Zig)
- Your code never leaves your PC; works offline after the first download
- Colorful menu, interactive Python console, multi-line input (`:run` to execute)

## Usage
```powershell
powershell -ExecutionPolicy Bypass -File .\FATYAK-Shell.ps1
```
To remove everything, delete `%LOCALAPPDATA%\FATYAK`. To change a version, edit its URL in the `$Catalog` table.

## Website
`docs/index.html` is the project site. On GitHub: Settings > Pages > Deploy from branch > `/docs`.

## License
MIT - FATYAK
