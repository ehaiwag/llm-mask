# llm-mask

**llm-mask** is a lightweight local tool that allows you to safely send text containing sensitive information to LLMs (ChatGPT, Claude, etc.).

It replaces sensitive information with tokens before sending the text to an LLM and restores the original values afterward.

The tool is designed for a **clipboard-based workflow**, making it especially convenient when using **Web ChatGPT**.

---

# Core Idea

Before sending text to an LLM:

```
Original text
↓
mask (replace sensitive data with tokens)
↓
Send to LLM
↓
LLM returns response
↓
unmask (restore original data)
↓
Recovered original content
```

Example

Original text

```
My email is cass@example.com and the project is ProjectX.
```

Masked text

```
My email is ⟦EMAIL_1_ab12cd⟧ and the project is ⟦PHRASE_1_cd34ef⟧.
```

Mapping file

```json
{
  "⟦EMAIL_1_ab12cd⟧": "cass@example.com",
  "⟦PHRASE_1_cd34ef⟧": "ProjectX"
}
```

After receiving the LLM response, `unmaskclip` restores the original values.

---

# Features

- reversible masking
- company / project name masking
- custom keyword masking
- automatic detection of common sensitive patterns
  - email
  - IP address
  - API keys
  - JWT tokens
- clipboard workflow (ideal for Web ChatGPT)
- macOS and Linux support
- temporary masking keywords
- local mapping files (never sent to LLM)

---

# Installation

Install with one command

```
curl -fsSL https://raw.githubusercontent.com/ehaiwag/llm-mask/main/install.sh | bash
```

Restart your shell

```
source ~/.zshrc
```

---

# Installer Options

Clean reinstall

```
curl -fsSL https://raw.githubusercontent.com/ehaiwag/llm-mask/main/install.sh | bash -s -- --clean
```

Uninstall

```
curl -fsSL https://raw.githubusercontent.com/ehaiwag/llm-mask/main/install.sh | bash -s -- --uninstall
```

Install to custom directory

```
curl -fsSL https://raw.githubusercontent.com/ehaiwag/llm-mask/main/install.sh | bash -s -- --prefix ~/.local/llm-mask
```

Quiet installation

```
curl -fsSL https://raw.githubusercontent.com/ehaiwag/llm-mask/main/install.sh | bash -s -- --quiet
```

---

# Usage

## Mask clipboard content

```
maskclip
```

Workflow

```
Copy text
↓
maskclip
↓
Paste into ChatGPT
```

---

## Mask with temporary keywords

```
maskclip "keyword1,keyword2"
```

These keywords apply **only to the current masking operation**.

---

## Restore ChatGPT output

```
unmaskclip
```

Workflow

```
Copy ChatGPT response
↓
unmaskclip
↓
Paste restored text
```

---

## Restore using a specific mapping file

```
unmaskclip path/to/map.json
```

---

# Real Usage Example

Example scenario: sending infrastructure logs to ChatGPT.

Original log

```
Service deployed to cn40 cluster by ProjectX
API endpoint: https://corp.example.com/api
```

Masked version

```
Service deployed to ⟦PHRASE_1_x83fa2⟧ cluster by ⟦PHRASE_2_8dd1a4⟧
API endpoint: ⟦URL_1_ae22f1⟧
```

ChatGPT analyzes the log safely without seeing sensitive information.

After running `unmaskclip`, the original values are restored.

---

# Sensitive Word Configuration

Sensitive phrases are stored in

```
~/.llm-mask/sensitive.txt
```

Example

```
# company names
YourCompany
YourCompanyAbbr

# projects
ProjectX
PhoenixCluster

# infrastructure
llm-access
corp.example.com
```

Rules

- one phrase per line
- `#` starts a comment
- matching is case-insensitive

---

# How Masking Works

1. Sensitive phrases and patterns are detected.
2. Each sensitive value is replaced with a unique token.
3. A mapping file records the relationship.

Example token

```
⟦TYPE_INDEX_RANDOM⟧
```

Examples

```
⟦EMAIL_1_ab12cd⟧
⟦PHRASE_2_cd34ef⟧
```

The mapping file allows the original text to be restored later.

---

# Mapping Files

Mapping files store token-to-original-value relationships.

Location

```
~/.llm-mask/maps/
```

Example

```
~/.llm-mask/maps/2026-03-04_104212.json
```

The most recent mapping file is stored in

```
~/.llm-mask/last_map
```

---

# Clipboard Support

The tool automatically detects clipboard utilities.

| OS | Clipboard Tool |
|----|---------------|
| macOS | pbcopy / pbpaste |
| Linux | xclip |

Install xclip on Linux

```
sudo apt install xclip
```

---

# Architecture

The project follows a simple layered design.

```
maskclip / unmaskclip
        │
        ▼
shell wrapper (llm-mask.sh)
        │
        ▼
Python core logic (llm_mask.py)
```

Components

| Component | Purpose |
|---|---|
| install.sh | installer |
| llm_mask.py | masking engine |
| llm-mask.sh | CLI wrapper |
| sensitive.txt | user maintained keywords |

This design keeps:

- **CLI logic in shell**
- **masking logic in Python**
- **installation logic in install.sh**

---

# Security Model

Important rules

- Mapping files remain **local only**
- Mapping files should **never be sent to LLMs**
- Tokens contain **no sensitive data**

Recommended permissions

```
chmod 600 ~/.llm-mask/maps/*
```

Optional cleanup

```
find ~/.llm-mask/maps -mtime +7 -delete
```

---

# ChatGPT Prompt Recommendation

To reduce the risk of token modification, add this instruction:

```
Do not modify any tokens wrapped by ⟦ and ⟧.
Keep them exactly unchanged.
```

---

# Troubleshooting

### maskclip command not found

Restart your shell

```
source ~/.zshrc
```

---

### clipboard not working

Check clipboard tool

macOS

```
pbcopy
pbpaste
```

Linux

```
sudo apt install xclip
```

---

### mapping file missing

Ensure `maskclip` was executed before `unmaskclip`.

---

# Roadmap

Possible future improvements

- pip install support
- automatic mapping cleanup
- fuzzy token recovery (if LLM modifies tokens)
- browser extension integration
- Raycast / Alfred integration
- automatic secret detection (NER)

---

# Project Structure

```
llm-mask/
│
├── install.sh
│
├── bin/
│   └── llm_mask.py
│
├── shell/
│   └── llm-mask.sh
│
└── config/
    └── sensitive.example.txt
```

---

# License

MIT
