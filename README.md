# llm-mask

**llm-mask** is a local reversible masking tool designed to safely send text containing sensitive information to LLMs (ChatGPT, Claude, etc.).

It replaces sensitive information with tokens before sending the text to an LLM and restores the original values afterward.

The tool is optimized for a **clipboard-based workflow**, which works especially well with **Web ChatGPT**.

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

Example:

Original text:

```
My email is cass@example.com and the project is ProjectX.
```

Masked text:

```
My email is ⟦EMAIL_1_ab12cd⟧ and the project is ⟦PHRASE_1_cd34ef⟧.
```

Mapping file:

```json
{
  "⟦EMAIL_1_ab12cd⟧": "cass@example.com",
  "⟦PHRASE_1_cd34ef⟧": "ProjectX"
}
```

After receiving the LLM response, `unmask` restores the original values.

---

# Features

- Reversible masking
- Company name masking
- Custom keyword masking
- Automatic detection of common sensitive patterns:
  - Email
  - IP address
  - API keys
  - JWT tokens
- Clipboard workflow (ideal for Web ChatGPT)
- macOS and Linux support
- Temporary masking keywords
- Local mapping files (never sent to LLM)

---

# Installation

Install with one command:

```bash
curl -s https://raw.githubusercontent.com/YOURNAME/llm-mask/main/install.sh | bash
```

After installation, the following directory is created:

```
~/.llm-mask/
│
├── sensitive.txt
├── last_map
│
└── maps/
```

Restart your shell or run:

```bash
source ~/.zshrc
```

---

# Usage

## Mask clipboard content

```
maskclip
```

Workflow:

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

Workflow:

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

# Sensitive Word Configuration

Sensitive phrases are stored in:

```
~/.llm-mask/sensitive.txt
```

Example:

```
# company names
YourCompany
YourCompanyAbbr

# projects
ProjectX
PhoenixCluster

# infrastructure
cn40
llm-access
corp.example.com
```

Rules:

- One phrase per line
- `#` is treated as a comment
- Matching is case-insensitive by default

---

# Token Format

Masked tokens follow this structure:

```
⟦TYPE_INDEX_RANDOM⟧
```

Examples:

```
⟦EMAIL_1_ab12cd⟧
⟦PHRASE_2_cd34ef⟧
```

Design goals:

- Avoid collisions with natural language
- Reduce the chance of LLM modifying tokens
- Ensure uniqueness

---

# Mapping Files

Mapping files store token-to-original-value relationships.

Location:

```
~/.llm-mask/maps/
```

Example:

```
~/.llm-mask/maps/2026-03-04_104212.json
```

The most recent mapping file is stored in:

```
~/.llm-mask/last_map
```

This allows `unmaskclip` to automatically restore the latest masked text.

---

# Security Notes

Mapping files should **never be sent to LLMs**.

Recommended permissions:

```bash
chmod 600 ~/.llm-mask/maps/*
```

Optional cleanup of old mappings:

```bash
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

# System Requirements

- Python 3
- macOS or Linux

Clipboard tools:

| OS | Clipboard Tool |
|----|---------------|
| macOS | pbcopy / pbpaste |
| Linux | xclip |

Install xclip on Linux:

```bash
sudo apt install xclip
```

---

# Project Structure

```
llm-mask/
│
├── README.md
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
